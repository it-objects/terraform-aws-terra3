import boto3
import os

ec2 = boto3.client('ec2')
route53 = boto3.client('route53')


def lambda_handler(event, context):
    zone_id = os.environ['ZONE_ID']
    record_name = os.environ['RECORD_NAME']
    asg_name = os.environ['ASG_NAME']

    print(f"Event received: {event}")
    print(f"Looking for instances in ASG: {asg_name}")

    # Check if this event is for an instance in our ASG
    event_instance_id = event.get('detail', {}).get('instance-id')
    if event_instance_id:
        print(f"Event is for instance: {event_instance_id}")
        # Verify the instance is in our ASG
        response = ec2.describe_instances(
            InstanceIds=[event_instance_id],
            Filters=[
                {'Name': 'tag:aws:autoscaling:groupName', 'Values': [asg_name]}
            ]
        )
        instances_in_asg = []
        for reservation in response.get('Reservations', []):
            instances_in_asg.extend(reservation.get('Instances', []))

        if not instances_in_asg:
            print(f"Instance {event_instance_id} is not in ASG {asg_name}, skipping")
            return {'statusCode': 200, 'body': 'Event is not for this ASG'}

    # Get running instances in the ASG
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:aws:autoscaling:groupName', 'Values': [asg_name]},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    # Extract private IP from running instance
    instances = []
    for reservation in response.get('Reservations', []):
        instances.extend(reservation.get('Instances', []))

    if not instances:
        print(f"No running instances found in ASG {asg_name}")
        return {'statusCode': 404, 'body': 'No instances found'}

    private_ip = instances[0]['PrivateIpAddress']
    instance_id = instances[0]['InstanceId']
    print(f"Found instance {instance_id} with IP {private_ip}")

    # Update Route53 record
    try:
        result = route53.change_resource_record_sets(
            HostedZoneId=zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record_name,
                            'Type': 'A',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': private_ip}]
                        }
                    }
                ]
            }
        )
        change_id = result.get('ChangeInfo', {}).get('Id')
        print(f"Successfully updated Route53 record {record_name} with IP {private_ip}, Change ID: {change_id}")
        return {'statusCode': 200, 'body': f'Updated {record_name} -> {private_ip}'}
    except Exception as e:
        print(f"Error updating Route53: {str(e)}")
        return {'statusCode': 500, 'body': str(e)}
