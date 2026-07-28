#!/bin/bash
yum install -y python3-pip wget unzip
sudo pip3 install --ignore-installed boto3 pandas scikit-learn mlflow
python3 -c "import boto3; boto3.client('s3', region_name='us-east-1').download_file('modular-mlops-bucket',
'scripts/train.py','/home/ec2-user/train.py')"
sudo touch /var/log/training.log && sudo chmod 666 /var/log/training.log

# --- PROMTAIL ---
LOKI_VERSION="2.9.4"
cd /tmp
wget -q https://github.com/grafana/loki/releases/download/v$${LOKI_VERSION}/promtail-linux-amd64.zip
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
    - url: ${loki_url}

scrape_configs:
  - job_name: training
    static_configs:
        - targets: [localhost]
          labels:
            job: training
            __path__: /var/log/training.log
EOF

cat > /etc/systemd/system/promtail.service << 'EOF'
[Unit]
Description=Promtail
After=network.target

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

python3 /home/ec2-user/train.py >> /var/log/training.log 2>&1