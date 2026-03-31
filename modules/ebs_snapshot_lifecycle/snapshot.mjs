// EBS Snapshot Lifecycle Lambda Handler
// Automatically snapshots EBS volumes when ECS Fargate tasks are stopping
// and updates the ECS service volume config with the new snapshot.
//
// Supports two trigger modes:
// 1. Task stop (EventBridge ECS task state change):
//    Pause service → snapshot → update service with new snapshot
// 2. Scheduled backup (EventBridge cron):
//    Discover running task → live snapshot → no service changes
//
// Safety features:
// - DynamoDB idempotency: prevents concurrent invocations from racing
// - Loop prevention: skips events when service has multiple active deployments
// - Failure blocking: sets SSM to "failed" and desiredCount=0 on snapshot failure
// - Snapshot completion wait: polls until snapshot is complete before updating service
// - Cleanup protects snapshots still referenced by the service

import { EC2Client, CreateSnapshotCommand, DescribeSnapshotsCommand, DeleteSnapshotCommand } from "@aws-sdk/client-ec2";
import { SSMClient, PutParameterCommand } from "@aws-sdk/client-ssm";
import { ECSClient, DescribeServicesCommand, UpdateServiceCommand, ListTasksCommand, DescribeTasksCommand } from "@aws-sdk/client-ecs";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
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
  BACKUP_RETENTION_COUNT,
} = process.env;

const SNAPSHOT_POLL_INTERVAL_MS = 10000;
const SNAPSHOT_POLL_TIMEOUT_MS = 540000;
const MANAGED_BY_TAG = "managed-by";
const MANAGED_BY_VALUE = "terra3-ebs-snapshot-lifecycle";
const SNAPSHOT_TYPE_TAG = "snapshot-type";
const SNAPSHOT_TYPE_LIFECYCLE = "lifecycle";
const SNAPSHOT_TYPE_BACKUP = "backup";

export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  // Scheduled backup: discover running task's volume and snapshot live
  if (event.source === "aws.events" && event["detail-type"] === "Scheduled Event") {
    await handleScheduledBackup();
    return;
  }

  // Task stop: existing lifecycle flow
  const { attachments, group, taskArn } = event.detail;

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

  // --- Get current service state ---
  const descResp = await ecs.send(new DescribeServicesCommand({
    cluster: ECS_CLUSTER_ARN,
    services: [ECS_SERVICE_NAME],
  }));
  const service = descResp.services?.[0];
  if (!service) {
    console.error(`Service ${ECS_SERVICE_NAME} not found`);
    return;
  }

  // --- Loop prevention ---
  // If there are multiple active deployments, a rollout is already in progress
  // (e.g. terraform apply or a previous Lambda invocation). Skip to avoid stacking deployments.
  const activeDeployments = (service.deployments || []).filter(d => d.status !== "INACTIVE");
  if (activeDeployments.length > 1) {
    console.log(`Skipping — ${activeDeployments.length} deployments already active. Will be handled by next task stop.`);
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

  // --- Pause service: desiredCount=0 prevents ECS from launching replacement with old snapshot ---
  // Changing only desiredCount does NOT create a new deployment.
  const originalDesiredCount = Math.max(service.desiredCount, 1);
  try {
    await ecs.send(new UpdateServiceCommand({
      cluster: ECS_CLUSTER_ARN,
      service: ECS_SERVICE_NAME,
      desiredCount: 0,
    }));
    console.log(`Paused service (desiredCount 0, was ${service.desiredCount})`);
  } catch (err) {
    console.warn(`Failed to pause service: ${err.message}`);
  }

  console.log(`Creating snapshot for volume ${volumeId}`);

  try {
    // Create snapshot
    const snapshot = await createSnapshot(volumeId);
    if (!snapshot) return; // handleFailure already called

    // Wait for completion
    const completed = await waitForSnapshotCompletion(snapshot.SnapshotId);
    if (!completed) {
      console.error(`SNAPSHOT_FAILED: Snapshot ${snapshot.SnapshotId} did not complete within timeout`);
      await handleFailure(volumeId, taskArn, `Snapshot ${snapshot.SnapshotId} timed out after ${SNAPSHOT_POLL_TIMEOUT_MS}ms`);
      return;
    }

    console.log(`Snapshot ${snapshot.SnapshotId} completed`);

    // Store in SSM
    await ssm.send(new PutParameterCommand({
      Name: SSM_PARAM_NAME,
      Value: snapshot.SnapshotId,
      Type: "String",
      Overwrite: true,
    }));

    // Record success
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

    console.log(`Stored ${snapshot.SnapshotId} in SSM: ${SSM_PARAM_NAME}`);

    // --- Single UpdateService: new volume config + restore desiredCount ---
    // This creates exactly ONE new deployment with the correct snapshot.
    await updateServiceWithSnapshot(service, snapshot.SnapshotId, originalDesiredCount);

    // Cleanup old snapshots (protects in-use snapshots)
    await cleanupSnapshots();
  } catch (err) {
    console.error(`SNAPSHOT_FAILED: Unexpected error for volume ${volumeId}: ${err.message}`);
    await handleFailure(volumeId, taskArn, `Unexpected error: ${err.message}`);
    throw err;
  }
};

async function createSnapshot(volumeId, snapshotType = SNAPSHOT_TYPE_LIFECYCLE) {
  const typeLabel = snapshotType === SNAPSHOT_TYPE_BACKUP ? "backup" : "auto";
  try {
    const snapshot = await ec2.send(new CreateSnapshotCommand({
      VolumeId: volumeId,
      Description: `${typeLabel === "backup" ? "Scheduled backup" : "Auto-snapshot"} for ${SOLUTION_NAME}/${APP_COMPONENT_NAME}`,
      TagSpecifications: [{
        ResourceType: "snapshot",
        Tags: [
          { Key: "Name", Value: `${SOLUTION_NAME}-${APP_COMPONENT_NAME}-${typeLabel}` },
          { Key: "solution_name", Value: SOLUTION_NAME },
          { Key: "app_component", Value: APP_COMPONENT_NAME },
          { Key: MANAGED_BY_TAG, Value: MANAGED_BY_VALUE },
          { Key: SNAPSHOT_TYPE_TAG, Value: snapshotType },
        ]
      }]
    }));
    console.log(`Snapshot created (${snapshotType}): ${snapshot.SnapshotId}`);
    return snapshot;
  } catch (err) {
    if (err.name === "IncorrectState") {
      console.error(`SNAPSHOT_FAILED: Volume ${volumeId} in IncorrectState`);
      if (snapshotType === SNAPSHOT_TYPE_LIFECYCLE) {
        await handleFailure(volumeId, volumeId, `Volume ${volumeId} in IncorrectState`);
      }
      return null;
    }
    throw err;
  }
}

async function waitForSnapshotCompletion(snapshotId) {
  const start = Date.now();
  while (Date.now() - start < SNAPSHOT_POLL_TIMEOUT_MS) {
    const resp = await ec2.send(new DescribeSnapshotsCommand({ SnapshotIds: [snapshotId] }));
    const snap = resp.Snapshots?.[0];
    if (!snap) return false;
    if (snap.State === "completed") return true;
    if (snap.State === "error") return false;
    console.log(`Snapshot ${snapshotId}: ${snap.State}, ${snap.Progress}`);
    await new Promise(resolve => setTimeout(resolve, SNAPSHOT_POLL_INTERVAL_MS));
  }
  return false;
}

async function updateServiceWithSnapshot(service, snapshotId, desiredCount) {
  // volumeConfigurations lives on the deployment, not the service object
  const primaryDeployment = (service.deployments || []).find(d => d.status === "PRIMARY");
  const sourceVolumeConfigs = primaryDeployment?.volumeConfigurations || service.volumeConfigurations || [];

  const volumeConfigs = sourceVolumeConfigs.map(vc => {
    const ebs = vc.managedEBSVolume || {};
    const config = {
      name: vc.name,
      managedEBSVolume: {
        roleArn: ebs.roleArn,
        encrypted: ebs.encrypted,
        sizeInGb: ebs.sizeInGiB || ebs.sizeInGb,
        volumeType: ebs.volumeType,
        snapshotId: vc.name === VOLUME_NAME ? snapshotId : ebs.snapshotId,
        filesystemType: ebs.filesystemType || FILE_SYSTEM_TYPE || "ext4",
      }
    };
    if (ebs.iops) config.managedEBSVolume.iops = ebs.iops;
    if (ebs.throughput) config.managedEBSVolume.throughput = ebs.throughput;
    if (ebs.kmsKeyId) config.managedEBSVolume.kmsKeyId = ebs.kmsKeyId;
    return config;
  });

  if (volumeConfigs.length === 0) {
    console.warn("No volume configurations found on service — restoring desiredCount only");
    await ecs.send(new UpdateServiceCommand({
      cluster: ECS_CLUSTER_ARN,
      service: ECS_SERVICE_NAME,
      desiredCount,
    }));
    return;
  }

  await ecs.send(new UpdateServiceCommand({
    cluster: ECS_CLUSTER_ARN,
    service: ECS_SERVICE_NAME,
    taskDefinition: service.taskDefinition,
    volumeConfigurations: volumeConfigs,
    desiredCount,
    propagateTags: "SERVICE",
    enableExecuteCommand: service.enableExecuteCommand,
  }));

  console.log(`Updated service: snapshot=${snapshotId}, desiredCount=${desiredCount}`);
}

async function handleFailure(volumeId, taskArn, reason) {
  try {
    await ssm.send(new PutParameterCommand({
      Name: SSM_PARAM_NAME, Value: "failed", Type: "String", Overwrite: true,
    }));
  } catch (err) {
    console.error(`Failed to set SSM to 'failed': ${err.message}`);
  }

  try {
    await ddb.send(new PutItemCommand({
      TableName: DYNAMODB_TABLE_NAME,
      Item: {
        volumeId: { S: volumeId }, taskArn: { S: taskArn },
        status: { S: "failed" }, reason: { S: reason },
        timestamp: { S: new Date().toISOString() },
        expiresAt: { N: String(Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60) },
      },
    }));
  } catch (err) {
    console.error(`Failed to record failure in DynamoDB: ${err.message}`);
  }

  try {
    await ecs.send(new UpdateServiceCommand({
      cluster: ECS_CLUSTER_ARN, service: ECS_SERVICE_NAME, desiredCount: 0,
    }));
    console.log(`Set desiredCount to 0 to prevent restart with stale data`);
  } catch (err) {
    console.error(`Failed to set desiredCount to 0: ${err.message}`);
  }

  if (SNS_TOPIC_ARN) {
    try {
      await sns.send(new PublishCommand({
        TopicArn: SNS_TOPIC_ARN,
        Subject: `EBS Snapshot Failed: ${SOLUTION_NAME}/${APP_COMPONENT_NAME}`,
        Message: JSON.stringify({
          solution: SOLUTION_NAME, appComponent: APP_COMPONENT_NAME,
          volumeId, taskArn, reason,
          action: "Service desiredCount set to 0. Manual intervention required.",
          recovery: "Set SSM parameter to a valid snapshot ID or 'none', then update desiredCount.",
          ssmParameter: SSM_PARAM_NAME, timestamp: new Date().toISOString(),
        }, null, 2),
      }));
    } catch (err) {
      console.error(`Failed to publish to SNS: ${err.message}`);
    }
  }
}

async function cleanupSnapshots() {
  const retentionCount = Number.parseInt(RETENTION_COUNT, 10) || 3;

  // Find which snapshots the ECS service currently references — never delete them
  const protectedSnapshots = new Set();
  try {
    const descResp = await ecs.send(new DescribeServicesCommand({
      cluster: ECS_CLUSTER_ARN,
      services: [ECS_SERVICE_NAME],
    }));
    for (const vc of descResp.services?.[0]?.volumeConfigurations || []) {
      if (vc.managedEBSVolume?.snapshotId) {
        protectedSnapshots.add(vc.managedEBSVolume.snapshotId);
      }
    }
    if (protectedSnapshots.size > 0) {
      console.log(`Protected snapshots (in use): ${[...protectedSnapshots].join(", ")}`);
    }
  } catch (err) {
    console.warn(`Could not determine in-use snapshots: ${err.message}. Skipping cleanup.`);
    return;
  }

  const existing = await ec2.send(new DescribeSnapshotsCommand({
    Filters: [
      { Name: "tag:solution_name", Values: [SOLUTION_NAME] },
      { Name: "tag:app_component", Values: [APP_COMPONENT_NAME] },
      { Name: `tag:${MANAGED_BY_TAG}`, Values: [MANAGED_BY_VALUE] },
    ]
  }));

  // Only clean up lifecycle snapshots (or untagged legacy ones)
  const completed = (existing.Snapshots || [])
    .filter(s => s.State === "completed")
    .filter(s => {
      const typeTag = s.Tags?.find(t => t.Key === SNAPSHOT_TYPE_TAG)?.Value;
      return !typeTag || typeTag === SNAPSHOT_TYPE_LIFECYCLE;
    })
    .sort((a, b) => new Date(b.StartTime) - new Date(a.StartTime));

  const toDelete = completed.slice(retentionCount).filter(s => !protectedSnapshots.has(s.SnapshotId));
  for (const snap of toDelete) {
    try {
      await ec2.send(new DeleteSnapshotCommand({ SnapshotId: snap.SnapshotId }));
      console.log(`Deleted old lifecycle snapshot: ${snap.SnapshotId}`);
    } catch (err) {
      console.warn(`Failed to delete snapshot ${snap.SnapshotId}: ${err.message}`);
    }
  }

  console.log(`Lifecycle cleanup: kept ${Math.min(completed.length, retentionCount)}, deleted ${toDelete.length}`);
}

// -----------------------------------------------
// Scheduled Backup
// -----------------------------------------------

async function handleScheduledBackup() {
  console.log("Scheduled backup triggered");

  // Discover running task and its EBS volume
  const listResp = await ecs.send(new ListTasksCommand({
    cluster: ECS_CLUSTER_ARN,
    serviceName: ECS_SERVICE_NAME,
    desiredStatus: "RUNNING",
  }));

  if (!listResp.taskArns?.length) {
    console.log("No running tasks found, skipping scheduled backup");
    return;
  }

  const descResp = await ecs.send(new DescribeTasksCommand({
    cluster: ECS_CLUSTER_ARN,
    tasks: [listResp.taskArns[0]],
  }));

  const task = descResp.tasks?.[0];
  const ebsAttachment = task?.attachments?.find(a =>
    a.type === "amazonebs" || a.type === "AmazonElasticBlockStorage"
  );
  const volumeId = ebsAttachment?.details?.find(d => d.name === "volumeId")?.value;

  if (!volumeId) {
    console.log("No EBS volume found on running task, skipping");
    return;
  }

  console.log(`Creating scheduled backup for volume ${volumeId}`);

  const snapshot = await createSnapshot(volumeId, SNAPSHOT_TYPE_BACKUP);
  if (!snapshot) return;

  const completed = await waitForSnapshotCompletion(snapshot.SnapshotId);
  if (!completed) {
    console.error(`Scheduled backup snapshot ${snapshot.SnapshotId} did not complete within timeout`);
    return;
  }

  console.log(`Scheduled backup completed: ${snapshot.SnapshotId}`);
  await cleanupBackupSnapshots();
}

async function cleanupBackupSnapshots() {
  const retentionCount = Number.parseInt(BACKUP_RETENTION_COUNT, 10) || 7;

  const existing = await ec2.send(new DescribeSnapshotsCommand({
    Filters: [
      { Name: "tag:solution_name", Values: [SOLUTION_NAME] },
      { Name: "tag:app_component", Values: [APP_COMPONENT_NAME] },
      { Name: `tag:${MANAGED_BY_TAG}`, Values: [MANAGED_BY_VALUE] },
      { Name: `tag:${SNAPSHOT_TYPE_TAG}`, Values: [SNAPSHOT_TYPE_BACKUP] },
    ]
  }));

  const completed = (existing.Snapshots || [])
    .filter(s => s.State === "completed")
    .sort((a, b) => new Date(b.StartTime) - new Date(a.StartTime));

  const toDelete = completed.slice(retentionCount);
  for (const snap of toDelete) {
    try {
      await ec2.send(new DeleteSnapshotCommand({ SnapshotId: snap.SnapshotId }));
      console.log(`Deleted old backup snapshot: ${snap.SnapshotId}`);
    } catch (err) {
      console.warn(`Failed to delete backup snapshot ${snap.SnapshotId}: ${err.message}`);
    }
  }

  console.log(`Backup cleanup: kept ${Math.min(completed.length, retentionCount)}, deleted ${toDelete.length}`);
}
