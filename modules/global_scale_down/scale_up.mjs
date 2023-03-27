import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";
import { ECSClient, UpdateServiceCommand } from "@aws-sdk/client-ecs";
import { RDSClient, StartDBInstanceCommand } from "@aws-sdk/client-rds";

export const handler = async(event) => {


    const nat_asg_input_1 = {
      "AutoScalingGroupName": "nat-instance-template-eu-central-1a-20230322083709069600000010-asg",
      "MaxSize": event.desired,
      "MinSize": event.desired,
      "DesiredCapacity":event.desired,
    };
    const nat_asg_command_1 = new UpdateAutoScalingGroupCommand(nat_asg_input_1);
    const nat_asg_client_1 = new AutoScalingClient();
    await nat_asg_client_1.send(nat_asg_command_1);


    const nat_asg_input_2 = {
      "AutoScalingGroupName": "nat-instance-template-eu-central-1b-2023032208370906960000000e-asg",
      "MaxSize": event.desired,
      "MinSize": event.desired,
      "DesiredCapacity":event.desired,
    };
    const nat_asg_command_2 = new UpdateAutoScalingGroupCommand(nat_asg_input_2);
    const nat_asg_client_2 = new AutoScalingClient();
    await nat_asg_client_2.send(nat_asg_command_2);


    const main_asg_input = {
      "AutoScalingGroupName": "scale-down_autoscaling_group",
      "MaxSize": event.desired,
      "MinSize": event.desired,
      "DesiredCapacity":event.desired,
    };
    const main_asg_command = new UpdateAutoScalingGroupCommand(main_asg_input);
    const main_asg_client_3 = new AutoScalingClient();
    await main_asg_client_3.send(main_asg_command);


    const db_input = {
      "DBInstanceIdentifier": event.dbname,
    };
    const db_command = new StartDBInstanceCommand(db_input);
    const db_client = new RDSClient();
    await db_client.send(db_command);


    const ecs_input = {
      "cluster": event.clustername,
      "service": "my_app_componentService",
      "taskDefinition": "my_app_component",
      "desiredCount": event.desired,
    };
    const ecs_command = new UpdateServiceCommand(ecs_input);
    const ecs_client = new ECSClient();
    await ecs_client.send(ecs_command);
};
