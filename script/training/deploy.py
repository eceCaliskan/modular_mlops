import json
import subprocess
import boto3
import mlflow
from fastapi import FastAPI
from pydantic import BaseModel
from mlflow import MlflowClient
import logging
import time
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
app = FastAPI()

@app.get("/")
def home():
    return {"message": "FastAPI running on EC2"}

'''
    This method is responsible for returning the ID of the Monitoring_Deployment_Registry instance
'''
def get_monitoring_deployment_registry_instance():
    try:
        ec2 = boto3.client("ec2", region_name="us-east-1")
        # Querying instance
        response = ec2.describe_instances(
        Filters=[
            {
                "Name": "tag:Purpose",
                "Values": ['Monitoring_Deployment_Registry']
            },
            {"Name": "instance-state-name", "Values": ["running"]}   
        ]
        )
        
        instance_ids = [
            instance["PublicIpAddress"]
            for reservation in response["Reservations"]
            for instance in reservation["Instances"]
        ]
        logging.info(f"DEPLOYMENT - SUCCESS: ID of Instance Monitoring_Deployment_Registry successfully retrieved. Instance ID = {instance_ids[0]}")
        return instance_ids[0]
    except Exception as e:
        logging.error(f"DEPLOYMENT - ERROR: Failure retrieving the ID of Monitoring_Deployment_Registry instance. Exception: {e}")

'''
    This method is responsible for loading the latest champion
'''
def load_champion():
    try:
        model_uri = "models:/sk-learn-random-forest-reg-model@champion"
        logging.info(f"DEPLOYMENT - SUCCESS: Successfully retrieved the model with the champion alias")
        return mlflow.sklearn.load_model(model_uri)
    except Exception as e:
        logging.error(f"DEPLOYMENT - ERROR: Failure retrieving the model with the champion alias. Exception: {e}")
        model_uri = "models:/sk-learn-random-forest-reg-model"
        return mlflow.sklearn.load_model(model_uri)
      
class WineFeatures(BaseModel):
    fixed_acidity: float
    volatile_acidity: float
    citric_acid: float
    residual_sugar: float
    chlorides: float
    free_sulfur_dioxide: float
    total_sulfur_dioxide: float
    density: float
    pH: float
    sulphates: float
    alcohol: float

'''
    This endpoint is responsible for serving the model, calculating the confidence and initiate the rollback if the confidence is below threshold
'''
@app.post("/predict")
def predict(features: WineFeatures):
    try:
       logging.info(f'Rollback start time: {time.time()}')
       model = load_champion()
       data = [[
           features.fixed_acidity,
           features.volatile_acidity,
           features.citric_acid,
           features.residual_sugar,
           features.chlorides,
           features.free_sulfur_dioxide,
           features.total_sulfur_dioxide,
           features.density,
           features.pH,
           features.sulphates,
           features.alcohol,
       ]]
       prediction = model.predict(data)[0]
       confidence = model.predict_proba(data)[0].max()
       # Start the rollback process if the confidence is less than 0.7
       if confidence<0.7: rollback()
       print(json.dumps({
           "stage": "prediction",
           "prediction": int(prediction),
           "confidence": round(float(confidence), 4)
       }))
       logging.info(f"DEPLOYMENT - SUCCESS: Successfully calculated the model confidence. Prediction: {prediction}, confidence: {confidence}")
       return {"prediction": int(prediction), "confidence": round(float(confidence), 4)}
    except Exception as e:
        logging.error(f"DEPLOYMENT - ERROR: Failure calculating the model confidence prediction. Exception: {e}")

'''
    This method is responsible for rolling back to the previous version of the model
'''
def rollback():
    try:
        all_versions = client.search_model_versions("name='sk-learn-random-forest-reg-model'")
        sorted_versions = sorted(all_versions, key=lambda v: int(v.version))                                                                                                                       
        previous_version = sorted_versions[-2].version   
        client.set_registered_model_alias(
            name="sk-learn-random-forest-reg-model",
            alias="champion",
            version=previous_version
        )
        logging.info(f'Rollback end time: {time.time()}')
        logging.info(f"DEPLOYMENT - SUCCESS: Successfully rollback to the previous version of the model.")
    except Exception as e:
        logging.error(f"DEPLOYMENT - ERROR: Failure rolling back to previous version of the model. Exception: {e}")

remote_server_uri = get_monitoring_deployment_registry_instance()
mlflow.set_tracking_uri(f'http://{remote_server_uri}:8080')
client = MlflowClient()

