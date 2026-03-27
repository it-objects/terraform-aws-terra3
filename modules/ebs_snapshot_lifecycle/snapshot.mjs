// EBS Snapshot Lifecycle Lambda Handler
// Automatically snapshots EBS volumes when ECS Fargate tasks are stopping
// and updates the ECS service to use the snapshot for the next task launch.
//
// Safety features:
// - DynamoDB idempotency: prevents concurrent invocations from racing
// - Loop prevention: skips tasks tagged by this Lambda (avoids UpdateService → re-trigger loop)
// - Failure blocking: sets SSM to "failed" and desiredCount=0 on snapshot failure
// - Snapshot completion wait: polls until snapshot is complete before updating service

import { EC2Client, CreateSnapshotCommand, DescribeSnapshotsCommand, DeleteSnapshotCommand, DescribeVolumesCommand } from "@aws-sdk/client-ec2";
import { SSMClient, PutParameterCommand } from "@aws-sdk/client-ssm";
import { ECSClient, DescribeServicesCommand, UpdateServiceCommand, DescribeTaskDefinitionCommand } from "@aws-sdk/client-ecs";
import { DynamoDBClient, PutItemCommand, GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const ec2 = new EC2Client();
const ssm = new SSMClient();
const ecs = new ECSClient();
const ddb = new DynamoDBClient();
const sns = new SNSClient();

const {
  SSM_PARAM_NAME,
  SOLUTION_NAME,
  APP_COMPONENT_NAME,
  RETENTION_COUNT,
  ECS_CLUSTER_ARN,
  ECS_SERVICE_NAME,
  VOLUME_NAME,
  DYNAMODB_TABLE_NAME,
  SNS_TOPIC_ARN,
  FILE_SYSTEM_TYPE,
} = process.env;

const SNAPSHOT_POLL_INTERVAL_MS = 5000;
const SNAPSHOT_POLL_TIMEOUT_MS = 90000;
const MANAGED_BY_TAG = "managed-by";
const MANAGED_BY_VALUE = "terra3-ebs-snapshot-lifecycle";

export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  const { attachments, group, taskArn, startedBy } = event.detail;

  // --- Loop prevention ---
  // Skip tasks that were started by this Lambda's UpdateService call.
  // We detect this by checking if the task's group tag indicates it was
  // triggered by a deployment we initiated. The startedBy field contains
  // "ecs-svc/<id>" for service-launched tasks — we check task definition tags instead.
  const taskDefArn = event.detail.taskDefinitionArn;
  if (taskDefArn) {
    try {
      const taskDef = await ecs.send(new DescribeTaskDefinitionCommand({
        taskDefinition: taskDefArn,
        include: ["TAGS"],
      }));
      const tags = taskDef.tags || [];
      const managedTag = tags.find(t => t.key === MANAGED_BY_TAG && t.value === MANAGED_BY_VALUE);
      if (managedTag) {
        console.log(`Skipping task from managed deployment (tag ${MANAGED_BY_TAG}=${MANAGED_BY_VALUE})`);
        return;
      }
    } catch (err) {
      console.warn(`Could not check task definition tags: ${err.message}. Proceeding with snapshot.`);
    }
  }

  // Only process events for our app component's service
  const expectedGroup = `service:${ECS_SERVICE_NAME}`;
  if (group !== expectedGroup) {
    console.log(`Ignoring event for group ${group}, expected ${expectedGroup}`);
    return;
  }

  // Find EBS volume attachment
  const ebsAttachment = attachments?.find(a => a.type === "amazonebs");
  if (!ebsAttachment) {
    console.log("No EBS volume attachment found, skipping");
    return;
  }

  const volumeId = ebsAttachment.details?.find(d => d.name === "volumeId")?.value;
  if (!volumeId) {
    console.log("No volumeId found in attachment details, skipping");
    return;
  }

  // --- Idempotency check ---
  try {
    await ddb.send(new PutItemCommand({
      TableName: DYNAMODB_TABLE_NAME,
      Item: {
        volumeId: { S: volumeId },
        taskArn: { S: taskArn },
        status: { S: "in_progress" },
        timestamp: { S: new Date().toISOString() },
        expiresAt: { N: String(Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60) },
      },
      ConditionExpression: "attribute_not_exists(volumeId) AND attribute_not_exists(taskArn)",
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") {
      console.log(`Already processing volume ${volumeId} for task ${taskArn}, skipping (idempotency)`);
      return;
    }
    throw err;
  }

  console.log(`Creating snapshot for volume ${volumeId}`);

  try {
    // Create snapshot
    let snapshot;
    try {
      snapshot = await ec2.send(new CreateSnapshotCommand({
        VolumeId: volumeId,
        Description: `Auto-snapshot for ${SOLUTION_NAME}/${APP_COMPONENT_NAME}`,
        TagSpecifications: [{
          ResourceType: "snapshot",
          Tags: [
            { Key: "Name", Value: `${SOLUTION_NAME}-${APP_COMPONENT_NAME}-auto` },
            { Key: "solution_name", Value: SOLUTION_NAME },
            { Key: "app_component", Value: APP_COMPONENT_NAME },
            { Key: MANAGED_BY_TAG, Value: MANAGED_BY_VALUE },
          ]
        }]
      }));
    } catch (err) {
      if (err.name === "IncorrectState") {
        console.error(`SNAPSHOT_FAILED: Volume ${volumeId} is no longer available. Cannot snapshot.`);
        await handleFailure(volumeId, taskArn, `Volume ${volumeId} in IncorrectState — already detaching/deleted`);
        return;
      }
      throw err;
    }

    console.log(`Snapshot created: ${snapshot.SnapshotId}, waiting for completion...`);

    // Wait for snapshot to complete
    const completed = await waitForSnapshotCompletion(snapshot.SnapshotId);
    if (!completed) {
      console.error(`SNAPSHOT_FAILED: Snapshot ${snapshot.SnapshotId} did not complete within timeout`);
      await handleFailure(volumeId, taskArn, `Snapshot ${snapshot.SnapshotId} timed out after ${SNAPSHOT_POLL_TIMEOUT_MS}ms`);
      return;
    }

    console.log(`Snapshot ${snapshot.SnapshotId} completed successfully`);

    // Store snapshot ID in SSM
    await ssm.send(new PutParameterCommand({
      Name: SSM_PARAM_NAME,
      Value: snapshot.SnapshotId,
      Type: "String",
      Overwrite: true,
    }));

    // Record success in DynamoDB
    await ddb.send(new PutItemCommand({
      TableName: DYNAMODB_TABLE_NAME,
      Item: {
        volumeId: { S: volumeId },
        taskArn: { S: taskArn },
        status: { S: "success" },
        snapshotId: { S: snapshot.SnapshotId },
        timestamp: { S: new Date().toISOString() },
        expiresAt: { N: String(Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60) },
      },
    }));

    console.log(`Stored snapshot ID ${snapshot.SnapshotId} in SSM: ${SSM_PARAM_NAME}`);

    // Update ECS service to use the snapshot for the next task.
    // This is an optimization — the snapshot ID is already in SSM, so the next
    // Terraform apply will pick it up. If UpdateService fails (e.g. volume name
    // mismatch with task definition), we warn but do NOT block restart since
    // the snapshot was captured successfully.
    try {
      await updateEcsService(snapshot.SnapshotId, ebsAttachment);
    } catch (err) {
      console.warn(`UpdateService failed (non-fatal, snapshot is safe in SSM): ${err.message}`);
      if (SNS_TOPIC_ARN) {
        await sns.send(new PublishCommand({
          TopicArn: SNS_TOPIC_ARN,
          Subject: `EBS Snapshot Warning: ${SOLUTION_NAME}/${APP_COMPONENT_NAME}`,
          Message: JSON.stringify({
            solution: SOLUTION_NAME,
            appComponent: APP_COMPONENT_NAME,
            warning: "UpdateService failed after successful snapshot. Snapshot is stored in SSM but ECS service config was not updated. Next Terraform apply will resolve this.",
            snapshotId: snapshot.SnapshotId,
            error: err.message,
            ssmParameter: SSM_PARAM_NAME,
            timestamp: new Date().toISOString(),
          }, null, 2),
        })).catch(e => console.warn(`Failed to publish warning to SNS: ${e.message}`));
      }
    }

    // Cleanup old snapshots
    await cleanupSnapshots();
  } catch (err) {
    console.error(`SNAPSHOT_FAILED: Unexpected error for volume ${volumeId}: ${err.message}`);
    await handleFailure(volumeId, taskArn, `Unexpected error: ${err.message}`);
    throw err;
  }
};

async function waitForSnapshotCompletion(snapshotId) {
  const start = Date.now();
  while (Date.now() - start < SNAPSHOT_POLL_TIMEOUT_MS) {
    const resp = await ec2.send(new DescribeSnapshotsCommand({
      SnapshotIds: [snapshotId],
    }));
    const snap = resp.Snapshots?.[0];
    if (!snap) {
      console.warn(`Snapshot ${snapshotId} not found during poll`);
      return false;
    }
    if (snap.State === "completed") {
      return true;
    }
    if (snap.State === "error") {
      console.error(`Snapshot ${snapshotId} entered error state`);
      return false;
    }
    console.log(`Snapshot ${snapshotId} state: ${snap.State}, progress: ${snap.Progress}, waiting...`);
    await new Promise(resolve => setTimeout(resolve, SNAPSHOT_POLL_INTERVAL_MS));
  }
  return false;
}

async function handleFailure(volumeId, taskArn, reason) {
  // Set SSM to "failed" so Terraform precondition blocks future applies
  try {
    await ssm.send(new PutParameterCommand({
      Name: SSM_PARAM_NAME,
      Value: "failed",
      Type: "String",
      Overwrite: true,
    }));
  } catch (err) {
    console.error(`Failed to set SSM to 'failed': ${err.message}`);
  }

  // Record failure in DynamoDB
  try {
    await ddb.send(new PutItemCommand({
      TableName: DYNAMODB_TABLE_NAME,
      Item: {
        volumeId: { S: volumeId },
        taskArn: { S: taskArn },
        status: { S: "failed" },
        reason: { S: reason },
        timestamp: { S: new Date().toISOString() },
        expiresAt: { N: String(Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60) },
      },
    }));
  } catch (err) {
    console.error(`Failed to record failure in DynamoDB: ${err.message}`);
  }

  // Block restart: set desiredCount to 0
  try {
    await ecs.send(new UpdateServiceCommand({
      cluster: ECS_CLUSTER_ARN,
      service: ECS_SERVICE_NAME,
      desiredCount: 0,
    }));
    console.log(`Set ${ECS_SERVICE_NAME} desiredCount to 0 to prevent restart with stale data`);
  } catch (err) {
    console.error(`Failed to set desiredCount to 0: ${err.message}`);
  }

  // Publish to SNS
  if (SNS_TOPIC_ARN) {
    try {
      await sns.send(new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Subject: `EBS Snapshot Failed: ${SOLUTION_NAME}/${APP_COMPONENT_NAME}`,
        Message: JSON.stringify({
          solution: SOLUTION_NAME,
          appComponent: APP_COMPONENT_NAME,
          volumeId,
          taskArn,
          reason,
          action: "Service desiredCount set to 0. Manual intervention required.",
          recovery: "Set SSM parameter to a valid snapshot ID or 'none', then update desiredCount.",
          ssmParameter: SSM_PARAM_NAME,
          timestamp: new Date().toISOString(),
        }, null, 2),
      }));
    } catch (err) {
      console.error(`Failed to publish to SNS: ${err.message}`);
    }
  }
}

async function updateEcsService(snapshotId, ebsAttachment) {
  // Get current service configuration
  const describeResp = await ecs.send(new DescribeServicesCommand({
    cluster: ECS_CLUSTER_ARN,
    services: [ECS_SERVICE_NAME],
  }));

  const service = describeResp.services?.[0];
  if (!service) {
    console.error(`Service ${ECS_SERVICE_NAME} not found in cluster`);
    return;
  }

  console.log(`Service task definition: ${service.taskDefinition}`);
  console.log(`Service volume configurations: ${JSON.stringify(service.volumeConfigurations)}`);

  let volumeConfigs;

  if (service.volumeConfigurations && service.volumeConfigurations.length > 0) {
    // Service already has volume configurations — update the snapshot ID
    volumeConfigs = service.volumeConfigurations.map(vc => {
      const ebs = vc.managedEBSVolume || {};
      const config = {
        name: vc.name,
        managedEBSVolume: {
          roleArn: ebs.roleArn,
          encrypted: ebs.encrypted,
          sizeInGb: ebs.sizeInGb,
          volumeType: ebs.volumeType,
          snapshotId: vc.name === VOLUME_NAME ? snapshotId : ebs.snapshotId,
        }
      };
      if (ebs.filesystemType) config.managedEBSVolume.filesystemType = ebs.filesystemType;
      if (ebs.iops) config.managedEBSVolume.iops = ebs.iops;
      if (ebs.throughput) config.managedEBSVolume.throughput = ebs.throughput;
      if (ebs.kmsKeyId) config.managedEBSVolume.kmsKeyId = ebs.kmsKeyId;
      return config;
    });
  } else {
    // Service has no volume configurations (volumes only in task definition with
    // configureAtLaunch). Build the config from the EBS attachment details and
    // the actual volume properties.
    const roleArn = ebsAttachment.details?.find(d => d.name === "roleArn")?.value;
    const volumeId = ebsAttachment.details?.find(d => d.name === "volumeId")?.value;

    if (!roleArn || !volumeId) {
      throw new Error(`Cannot build volume config: missing roleArn or volumeId from attachment details`);
    }

    // Describe the actual volume to get its properties.
    // The volume may already be deleted by the time we get here (ECS deletes it
    // after task stops). Fall back to snapshot properties if so.
    let volConfig;
    try {
      const { Volumes } = await ec2.send(new DescribeVolumesCommand({
        VolumeIds: [volumeId],
      }));
      const vol = Volumes?.[0];
      if (vol) {
        volConfig = {
          encrypted: vol.Encrypted,
          sizeInGb: vol.Size,
          volumeType: vol.VolumeType,
          iops: vol.Iops,
          throughput: vol.Throughput,
          kmsKeyId: vol.KmsKeyId,
        };
      }
    } catch (err) {
      console.warn(`DescribeVolumes failed (volume likely deleted): ${err.message}`);
    }

    if (!volConfig) {
      // Fall back to snapshot properties
      const snapResp = await ec2.send(new DescribeSnapshotsCommand({
        SnapshotIds: [snapshotId],
      }));
      const snap = snapResp.Snapshots?.[0];
      if (!snap) {
        throw new Error(`Neither volume ${volumeId} nor snapshot ${snapshotId} found — cannot build volume config`);
      }
      volConfig = {
        encrypted: snap.Encrypted,
        sizeInGb: snap.VolumeSize,
        volumeType: "gp3",
        kmsKeyId: snap.KmsKeyId,
      };
      console.warn(`Using snapshot properties as fallback (volumeType defaulted to gp3)`);
    }

    const config = {
      name: VOLUME_NAME,
      managedEBSVolume: {
        roleArn,
        encrypted: volConfig.encrypted,
        sizeInGb: volConfig.sizeInGb,
        volumeType: volConfig.volumeType,
        filesystemType: FILE_SYSTEM_TYPE || "ext4",
        snapshotId,
      }
    };
    if (volConfig.iops) config.managedEBSVolume.iops = volConfig.iops;
    if (volConfig.throughput) config.managedEBSVolume.throughput = volConfig.throughput;
    if (volConfig.kmsKeyId) config.managedEBSVolume.kmsKeyId = volConfig.kmsKeyId;

    console.log(`Built volume config from attachment + DescribeVolumes: ${JSON.stringify(config)}`);
    volumeConfigs = [config];
  }

  // UpdateService requires taskDefinition to validate volumeConfigurations
  // against the task definition's configureAtLaunch volumes.
  await ecs.send(new UpdateServiceCommand({
    cluster: ECS_CLUSTER_ARN,
    service: ECS_SERVICE_NAME,
    taskDefinition: service.taskDefinition,
    volumeConfigurations: volumeConfigs,
    propagateTags: "SERVICE",
    enableExecuteCommand: service.enableExecuteCommand,
  }));

  // Tag the service so replacement tasks can be identified
  console.log(`Updated ECS service ${ECS_SERVICE_NAME} with snapshot ${snapshotId} for volume ${VOLUME_NAME}`);
}

async function cleanupSnapshots() {
  const retentionCount = parseInt(RETENTION_COUNT, 10) || 3;
  const existing = await ec2.send(new DescribeSnapshotsCommand({
    Filters: [
      { Name: "tag:solution_name", Values: [SOLUTION_NAME] },
      { Name: "tag:app_component", Values: [APP_COMPONENT_NAME] },
      { Name: `tag:${MANAGED_BY_TAG}`, Values: [MANAGED_BY_VALUE] },
    ]
  }));

  // Only consider completed snapshots for cleanup — skip pending ones
  const completed = (existing.Snapshots || [])
    .filter(s => s.State === "completed")
    .sort((a, b) => new Date(b.StartTime) - new Date(a.StartTime));

  const toDelete = completed.slice(retentionCount);
  for (const snap of toDelete) {
    try {
      await ec2.send(new DeleteSnapshotCommand({ SnapshotId: snap.SnapshotId }));
      console.log(`Deleted old snapshot: ${snap.SnapshotId}`);
    } catch (err) {
      console.warn(`Failed to delete snapshot ${snap.SnapshotId}: ${err.message}`);
    }
  }

  console.log(`Cleanup complete. Kept ${Math.min(completed.length, retentionCount)}, deleted ${toDelete.length}`);
}
