import boto3

region = 'us-east-1'

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    ssm = boto3.client('ssm', region_name=region)
    ssm.put_parameter(
        Name='/ml/input_file',
        Value=f's3://{bucket}/{key}',
        Type='String',
        Overwrite=True
    )

    ec2 = boto3.client('ec2', region_name=region)
    instances = ec2.describe_instances(Filters=[
        {'Name': 'tag:Name', 'Values': ['single-instance']},
        {'Name': 'instance-state-name', 'Values': ['stopped']}
    ])
    instance_id = instances['Reservations'][0]['Instances'][0]['InstanceId']
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[instance_id])

    ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': ['python3 /home/ec2-user/train.py']}
    )
    ec2.start_instances(InstanceIds=[instance_id])
    return {'statusCode': 200, 'body': 'EC starteddd'}



