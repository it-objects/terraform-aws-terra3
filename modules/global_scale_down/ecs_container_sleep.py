import boto3

client = boto3.client('ecs')

def lambda_handler(event, context):
    response = client.update_service(
        desiredCount=1,
        service='my_app_componentService',
        cluster='scale-down-cluster',
    )
