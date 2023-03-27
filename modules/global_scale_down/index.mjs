import { AutoScalingClient, UpdateAutoScalingGroupCommand } from "@aws-sdk/client-auto-scaling";

export const handler = async(event) => {

    // function for the first NAT AutoScaling Group
    const nat_asg_input_1 = {
      "AutoScalingGroupName": "nat-instance-template-eu-central-1a-20230314073831659400000009-asg",
      "MaxSize": 1,
      "MinSize": 1,
      "DesiredCapacity":1,
    };
    const nat_asg_command_1 = new UpdateAutoScalingGroupCommand(nat_asg_input_1);
    const nat_asg_client_1 = new AutoScalingClient();
    await nat_asg_client_1.send(nat_asg_command_1);


};
