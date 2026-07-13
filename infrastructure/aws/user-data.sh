#!/bin/bash

yum update -y

yum install python3-pip -y
python3 -m pip install boto3 fastapi[standard] gunicorn mlflow uvicorn scikit-learn pydantic --ignore-installed requests        
python3 -c "import boto3; boto3.client('s3', region_name='us-east-1').download_file('modular-mlops-bucket', 'scripts/deploy.py','main.py')"

mkdir /mlflow

nohup mlflow server \
  --host 0.0.0.0 \
  --port 8080 \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root s3://modular-mlops-bucket/mlflow-artifacts \
  >/var/log/mlflow.log 2>&1 &


nohup gunicorn main:app  -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 \
  > gunicorn.log 2>&1 &