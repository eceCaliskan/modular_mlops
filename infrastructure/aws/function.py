import boto3  
region = 'us-east-1'
instances = ['i-020b09d290075f3c1']
ec2 = boto3.client('ec2', region_name=region)

#Creating lambda function to store the bucket information in ssm to pass EC2
def lambda_handler(event, context):
      bucket = event['Records'][0]['s3']['bucket']['name']
      key = event['Records'][0]['s3']['object']['key']
      ssm = boto3.client('ssm')
      ssm.put_parameter(
          Name='/ml/input_file',
          Value=f's3://{bucket}/{key}',
          Type='String',
          Overwrite=True
      )
      #Starting EC2 instance
      ec2.start_instances(InstanceIds=instances)
      return {'statusCode': 200, 'body': 'EC2 started'}