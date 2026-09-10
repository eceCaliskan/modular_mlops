#This file is responsible for creating Lambda function operations to store
#dataset location to SSM and start training EC2 instance with command
#Main resources used in this file as follows,
#
#https://docs.python.org/3/library/urllib.request.html 
#https://docs.aws.amazon.com/code-library/latest/ug/python_3_ssm_code_examples.html
#https://docs.aws.amazon.com/code-library/latest/ug/python_3_ec2_code_examples.html
#
import boto3
import urllib.request
import json
import time

region = 'us-east-1'
ssm = boto3.client('ssm', region_name=region)

'''
    This method is responsible for pushing the logs to Loki API
    source https://docs.python.org/3/library/urllib.request.html
'''
def push_to_loki(message):
    loki_url = ssm.get_parameter(Name='/ml/loki_url')['Parameter']['Value']
    payload = json.dumps({
        "streams": [{
            "stream": {"job": "data"},
            "values": [[str(int(time.time() * 1e9)), message]]
        }]
    }).encode()
    req = urllib.request.Request(
        loki_url,
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception as e:
        print(f"Loki push failed: {e}")

'''
    This method is responsible for setting the location of the dataset file for EC2 to download
    source https://docs.aws.amazon.com/code-library/latest/ug/python_3_ssm_code_examples.html
'''
def set_file_location(event):
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        ssm.put_parameter(
                Name='/ml/input_file',
                Value=f's3://{bucket}/{key}',
                Type='String',
                Overwrite=True
        )
        push_to_loki('LAMBDA EVENT - SUCCESS: Dataset file location successfully set as an ssm parameter ')
    except Exception as e:
        push_to_loki(f'LAMBDA EVENT - ERROR: Failed to set Dataset file location. Exception: {e}')

"""
    This method is responsible for starting the EC2 training instance and triggering train.py script
    source https://docs.aws.amazon.com/code-library/latest/ug/python_3_ec2_code_examples.html
"""
def start_training_ec2():
    
    try:
        ec2 = boto3.client('ec2', region_name=region)
        instances = ec2.describe_instances(Filters=[
            {'Name': 'tag:Purpose', 'Values': ['Training']},
            {'Name': 'instance-state-name', 'Values': ['stopped']}
        ])
        instance_id = instances['Reservations'][0]['Instances'][0]['InstanceId']
        ec2.start_instances(InstanceIds=[instance_id])
        waiter = ec2.get_waiter('instance_running')
        waiter.wait(InstanceIds=[instance_id])
        ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName='AWS-RunShellScript',
            Parameters={'commands': ['python3 /home/ec2-user/train.py >> /var/log/training.log 2>&1']}
        )
        push_to_loki('LAMBDA EVENT - SUCCESS: EC2 instance successfully started')
    except Exception as e:
        push_to_loki(f'LAMBDA EVENT - FAILURE: EC2 instance failed to start. Exception: {e}')

def lambda_handler(event, context):
    push_to_loki('LAMBDA EVENT - SUCCESS: Dataset Successfully uploaded to S3 bucket')
    set_file_location(event)
    start_training_ec2()
    return {'statusCode': 200, 'body': 'EC2 Instance started'}

