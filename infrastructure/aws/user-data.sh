#!/bin/bash   
yum update -y                                                                                                                                                                              
                                                                                                                                                                                            
yum install -y python3-pip wget unzip                                                                                                                                                      
python3 -m pip install boto3 fastapi[standard] gunicorn mlflow uvicorn scikit-learn pydantic --ignore-installed requests                                                                   
python3 -c "import boto3; boto3.client('s3', region_name='us-east-1').download_file('modular-mlops-bucket', 'scripts/deploy.py','/home/ec2-user/main.py')"                                 
                                                                                                                                                                                            
                                                                                                                                                                                            
#INSTALL GRAFANA                                                                                                                                                                         
cat > /etc/yum.repos.d/grafana.repo << 'EOF'                                                                                                                                               
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
EOF

yum install -y grafana


mkdir -p /mlflow

cat > /etc/systemd/system/mlflow.service << 'EOF'
[Unit]
Description=MLflow Server
After=network.target

[Service]
WorkingDirectory=/mlflow
ExecStart=/usr/local/bin/mlflow server \
  --host 0.0.0.0 \
  --port 8080 \
  --backend-store-uri sqlite:////mlflow/mlflow.db \
  --default-artifact-root s3://modular-mlops-bucket/mlflow-artifacts
Restart=always
RestartSec=5
StandardOutput=append:/var/log/mlflow.log
StandardError=append:/var/log/mlflow.log

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/fastapi.service << 'EOF'
[Unit]
Description=FastAPI Deployment Server
After=network.target mlflow.service

[Service]
WorkingDirectory=/home/ec2-user
ExecStart=/usr/local/bin/gunicorn main:app -w 2 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
Restart=always
RestartSec=5
StandardOutput=append:/var/log/deployment.log
StandardError=append:/var/log/deployment.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mlflow fastapi grafana-server
systemctl start mlflow
systemctl start fastapi
systemctl start grafana-server