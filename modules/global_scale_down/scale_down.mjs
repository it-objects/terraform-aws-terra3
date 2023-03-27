import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { RDSClient, StopDBInstanceCommand } from "@aws-sdk/client-rds";

export const handler = async(event) => {


    const db_input = {
      "DBInstanceIdentifier": event.db_identifier,
    };
    const db_command = new StopDBInstanceCommand(db_input);
    const db_client = new RDSClient();
    await db_client.send(db_command);

    const ecs_input = {
      "cluster": event.clustername,
      "service": event.ecs_service_name,
      "taskDefinition": event.ecs_task_definition_name,
      "desiredCount": event.ecs_desire_task_count,
    };
    const ecs_command = new UpdateServiceCommand(ecs_input);
    const ecs_client = new ECSClient();
    await ecs_client.send(ecs_command);
};
