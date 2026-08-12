import json
import subprocess
import boto3
import mlflow
from fastapi import FastAPI
from pydantic import BaseModel
from mlflow import MlflowClient

app = FastAPI()

@app.get("/")
def home():
    return {"message": "FastAPI running on EC2"}


def get_instance_from_tag2(tagname):
    ec2 = boto3.client("ec2", region_name="us-east-1")
    response = ec2.describe_instances(
    Filters=[
        {
            "Name": "tag:Purpose",
            "Values": ['Monitoring']
        },
        {"Name": "instance-state-name", "Values": ["running"]}   
    ]
    )
    
    instance_ids = [
        instance["PublicIpAddress"]
        for reservation in response["Reservations"]
        for instance in reservation["Instances"]
    ]
    print('INSTANCE IDS', instance_ids)
    print(instance_ids)
    return instance_ids[0]

remote_server_uri = get_instance_from_tag2('Monitoring')
mlflow.set_tracking_uri(f'http://{remote_server_uri}:8080')
client = MlflowClient()

def load_champion():
      try:
        model_uri = "models:/sk-learn-random-forest-reg-model@champion"
        return mlflow.sklearn.load_model(model_uri)
      except:
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

@app.post("/predict")
def predict(features: WineFeatures):
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
       if confidence<0.7: rollback()
       print(json.dumps({
           "stage": "prediction",
           "prediction": int(prediction),
           "confidence": round(float(confidence), 4)
       }))
       return {"prediction": int(prediction), "confidence": round(float(confidence), 4)}

def rollback():
        all_versions = client.search_model_versions("name='sk-learn-random-forest-reg-model'")
        sorted_versions = sorted(all_versions, key=lambda v: int(v.version))                                                                                                                       
        previous_version = sorted_versions[-2].version   
        client.set_registered_model_alias(
            name="sk-learn-random-forest-reg-model",
            alias="champion",
            version=previous_version
        )