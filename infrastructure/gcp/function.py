#This file is responsible for triggering compute instance in GCP using cloud function
#Main resources used: 
# https://codelabs.developers.google.com/codelabs/secret-manager-python#5
# https://docs.cloud.google.com/python/docs/reference/compute/latest/google.cloud.compute_v1.services.instances.InstancesClient
#
from google.cloud import secretmanager, compute_v1

def trigger_training(event, context):
      bucket = event['bucket']
      key = event['name']
      #Add the dataset as secret to pass compute instance
      client = secretmanager.SecretManagerServiceClient()
      client.add_secret_version(
          parent="projects/project-a280d5fe-bdeb-4fbe-aa0/secrets/ml-input-file",
          payload={"data": f"gs://{bucket}/{key}".encode()}
      )
      compute = compute_v1.InstancesClient()
      #Starting the compute instance
      compute.start(project="project-a280d5fe-bdeb-4fbe-aa0", zone="us-central1-a", instance="default")






