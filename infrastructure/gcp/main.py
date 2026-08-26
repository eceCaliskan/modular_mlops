from google.cloud import secretmanager, compute_v1


def trigger_training(event, context):
      bucket = event['bucket']
      key = event['name']
      client = secretmanager.SecretManagerServiceClient()
      client.add_secret_version(
          parent="projects/project-a280d5fe-bdeb-4fbe-aa0/secrets/ml-input-file",
          payload={"data": f"gs://{bucket}/{key}".encode()}
      )
      compute = compute_v1.InstancesClient()
      compute.start(project="project-a280d5fe-bdeb-4fbe-aa0", zone="us-central1-a", instance="default")






