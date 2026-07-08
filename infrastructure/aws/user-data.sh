#!/bin/bash

yum update -y

yum install python3-pip -y
python3 -m pip install mlflow --ignore-installed requests        
mkdir /mlflow

nohup mlflow server \
  --host 0.0.0.0 \
  --port 8080 \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root /mlflow \
  >/var/log/mlflow.log 2>&1 &