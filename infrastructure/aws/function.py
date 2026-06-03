import boto3  
region = 'us-east-1'
instances = ['i-020b09d290075f3c1']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    print(event)
    ec2.start_instances(InstanceIds=instances)
    
    print('started your instances: ' + str(instances))

