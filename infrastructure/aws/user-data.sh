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

useradd --system loki || true
mkdir -p /etc/loki
mkdir -p /var/lib/loki
cd /tmp
wget https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
mv loki-linux-amd64 /usr/local/bin/loki
chmod +x /usr/local/bin/loki
sudo tee /etc/loki/config.yaml << 'EOF'
auth_enabled: false                         
                                      
server:
  http_listen_port: 3100                                                                                                                                      

common:                                                                                                                                                       
  path_prefix: /var/lib/loki                                                                                                                                
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: /var/lib/loki/chunks

limits_config:
  allow_structured_metadata: true
EOF

cat >/etc/systemd/system/loki.service <<EOF
[Unit]
Description=Loki
After=network.target

[Service]
User=loki
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

chown -R loki:loki /etc/loki
chown -R loki:loki /var/lib/loki
useradd --system --no-create-home promtail || true


# --- PROMTAIL ---                                                                                                                                            
LOKI_VERSION="2.9.4"                                                                                                                                          
cd /tmp                                                                                                                                                       
wget https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip                                                                                                                                
mv promtail-linux-amd64 /usr/local/bin/promtail                                                                                                               
chmod +x /usr/local/bin/promtail                                                                                                                              
                                                                                                                                                            
mkdir -p /etc/promtail /var/lib/promtail

cat > /etc/promtail/config.yaml << 'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: deployment
    static_configs:
      - targets: [localhost]
        labels:
          job: deployment
          __path__: /var/log/deployment.log
  - job_name: mlflow
    static_configs:
      - targets: [localhost]
        labels:
          job: mlflow
          __path__: /var/log/mlflow.log
EOF

cat > /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail
After=network.target loki.service

[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload
systemctl enable promtail
systemctl start promtail
systemctl daemon-reload
systemctl enable loki
systemctl start loki
systemctl daemon-reload
systemctl enable mlflow fastapi grafana-server
systemctl start mlflow
systemctl start fastapi
systemctl start grafana-server