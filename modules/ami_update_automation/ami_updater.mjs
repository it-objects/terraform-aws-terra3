import {
  EC2Client,
  DescribeImagesCommand,
  DescribeLaunchTemplateVersionsCommand,
  CreateLaunchTemplateVersionCommand,
} from "@aws-sdk/client-ec2";
import {
  AutoScalingClient,
  StartInstanceRefreshCommand,
  DescribeInstanceRefreshesCommand,
} from "@aws-sdk/client-auto-scaling";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const ec2 = new EC2Client();
const autoscaling = new AutoScalingClient();
const sns = new SNSClient();

export const handler = async () => {
  const {
    LAUNCH_TEMPLATE_ID,
    ASG_NAME,
    AMI_OWNERS,
    AMI_NAME_FILTER,
    AMI_ARCHITECTURE,
    AMI_ADDITIONAL_FILTERS,
    MIN_HEALTHY_PERCENTAGE,
    INSTANCE_WARMUP,
    SNS_TOPIC_ARN,
  } = process.env;

  const owners = JSON.parse(AMI_OWNERS);
  const additionalFilters = JSON.parse(AMI_ADDITIONAL_FILTERS);

  try {
    const filters = [
      { Name: "name", Values: [AMI_NAME_FILTER] },
      { Name: "architecture", Values: [AMI_ARCHITECTURE] },
      { Name: "state", Values: ["available"] },
    ];

    for (const [name, values] of Object.entries(additionalFilters)) {
      filters.push({ Name: name, Values: values });
    }

    const describeImagesResp = await ec2.send(
      new DescribeImagesCommand({ Owners: owners, Filters: filters })
    );

    if (!describeImagesResp.Images || describeImagesResp.Images.length === 0) {
      console.log("No AMIs found matching filters. Exiting.");
      return { statusCode: 200, body: "No matching AMIs found" };
    }

    const sortedImages = describeImagesResp.Images.sort(
      (a, b) => new Date(b.CreationDate) - new Date(a.CreationDate)
    );
    const latestAmi = sortedImages[0];
    console.log(
      `Latest AMI: ${latestAmi.ImageId} (${latestAmi.Name}), created ${latestAmi.CreationDate}`
    );

    const ltVersionsResp = await ec2.send(
      new DescribeLaunchTemplateVersionsCommand({
        LaunchTemplateId: LAUNCH_TEMPLATE_ID,
        Versions: ["$Latest"],
      })
    );

    const currentVersion = ltVersionsResp.LaunchTemplateVersions[0];
    const currentAmiId = currentVersion.LaunchTemplateData.ImageId;
    console.log(
      `Current launch template AMI: ${currentAmiId} (version ${currentVersion.VersionNumber})`
    );

    if (currentAmiId === latestAmi.ImageId) {
      console.log("AMI is already up to date. No action needed.");
      return { statusCode: 200, body: "AMI already up to date" };
    }

    const refreshesResp = await autoscaling.send(
      new DescribeInstanceRefreshesCommand({
        AutoScalingGroupName: ASG_NAME,
        MaxRecords: 1,
      })
    );

    const activeRefresh = refreshesResp.InstanceRefreshes?.find((r) =>
      ["Pending", "InProgress", "Cancelling"].includes(r.Status)
    );

    if (activeRefresh) {
      console.log(
        `Instance refresh already in progress (${activeRefresh.InstanceRefreshId}, status: ${activeRefresh.Status}). Skipping.`
      );
      return {
        statusCode: 409,
        body: `Instance refresh already in progress: ${activeRefresh.InstanceRefreshId}`,
      };
    }

    const createVersionResp = await ec2.send(
      new CreateLaunchTemplateVersionCommand({
        LaunchTemplateId: LAUNCH_TEMPLATE_ID,
        SourceVersion: String(currentVersion.VersionNumber),
        LaunchTemplateData: {
          ImageId: latestAmi.ImageId,
        },
        VersionDescription: `AMI update: ${currentAmiId} -> ${latestAmi.ImageId} (${latestAmi.Name})`,
      })
    );

    const newVersionNumber =
      createVersionResp.LaunchTemplateVersion.VersionNumber;
    console.log(
      `Created launch template version ${newVersionNumber} with AMI ${latestAmi.ImageId}`
    );

    const refreshResp = await autoscaling.send(
      new StartInstanceRefreshCommand({
        AutoScalingGroupName: ASG_NAME,
        Strategy: "Rolling",
        Preferences: {
          MinHealthyPercentage: parseInt(MIN_HEALTHY_PERCENTAGE, 10),
          InstanceWarmup: parseInt(INSTANCE_WARMUP, 10),
        },
      })
    );

    console.log(`Started instance refresh: ${refreshResp.InstanceRefreshId}`);

    if (SNS_TOPIC_ARN) {
      await sns.send(
        new PublishCommand({
          TopicArn: SNS_TOPIC_ARN,
          Subject: `[${ASG_NAME}] AMI Updated`,
          Message: JSON.stringify(
            {
              asgName: ASG_NAME,
              launchTemplateId: LAUNCH_TEMPLATE_ID,
              previousAmi: currentAmiId,
              newAmi: latestAmi.ImageId,
              newAmiName: latestAmi.Name,
              newAmiCreationDate: latestAmi.CreationDate,
              launchTemplateVersion: newVersionNumber,
              instanceRefreshId: refreshResp.InstanceRefreshId,
            },
            null,
            2
          ),
        })
      );
      console.log("SNS notification sent.");
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        updated: true,
        previousAmi: currentAmiId,
        newAmi: latestAmi.ImageId,
        instanceRefreshId: refreshResp.InstanceRefreshId,
      }),
    };
  } catch (error) {
    console.error("AMI update failed:", error);

    if (SNS_TOPIC_ARN) {
      try {
        await sns.send(
          new PublishCommand({
            TopicArn: SNS_TOPIC_ARN,
            Subject: `[${ASG_NAME}] AMI Update FAILED`,
            Message: `Error: ${error.message}\n\nStack: ${error.stack}`,
          })
        );
      } catch (snsError) {
        console.error("Failed to send SNS failure notification:", snsError);
      }
    }

    throw error;
  }
};
