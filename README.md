# Modular MLOps Pipeline

This project is built to demonstrate a cloud-based MLOps pipeline, reducing vendor lock-in using modular open-source components defined with IaC approach, improving reliability with champion-challanger based validation gate and model rollback functionalies and unifying the monitoring using Promtail, Grafana and Loki technologies.

This pipeline is a research artifact built to evaluate the extend to what this approaches provides portability, reliability and observability.

The pipeline is implmented in Amazon Web Services (AWS) and modular components are mapped to their equivelant components in Google Cloud Platform (GCP) to demonstrate the portability, hence reducing vender lock-in

The modularity of the pipelines is achieved by using independent cloud-native modular components.

## Overview

The pipeline investigates the research questions below:

1.	RQ1: To what extent does an IaC architecture reduce vendor lock-in in cloud-native MLOps pipelines?
2.	RQ2: To what extent do model version comparison, deployment success and rollback effectiveness support the reliability of a modular MLOps pipeline?
3.	RQ3: To what extent does monitoring within a modular MLOps pipeline support observability across each pipeline stage?

## Architecture

The pipeline is built using different cloud-native components, these components and Purposes are represented in the table below

| Component | AWS Service | Purpose
|---|---|---|
|Object Storage | Amazon S3 | Storing dataset, model artefact, scripts|
|Event trigger | Lambda + S3 Events | Stores the file location to SSM and starts training on new data |
|Training Instance | Amazon EC2 | Preprocesses and trains the model, runs the validation gate, stores the model to S3 bucket and MLflow | 
|registery, monitoring, deployment Instance | Amazon EC2 | Serves predictions with confidence metrics, triggers rollback |
Model Registry | MLflow | Model versioning and champion alias record | 
Monitoring | Grafana, Loki, Promtail | Unified, pipeline stage-based monitoring |
Infrastructure | Terraform | Infrastructure as Code provisioning |

## Repository Structure 
```
📂 modular_mlops
├── 📁 dataset # This folder contains the datasets used for the implementation and training
│   │   ├── 📄 WineQT.csv # Original Dataset
│   │   ├── 📄 WineQTcopy_champion.csv # This file sets IAM permissions required by AWS vendor using Terraform definitions
│   │   ├── 📄 WineQTcopy_fault_injection.csv # Evaluation dataset
│   │   ├── 📄 WineQTcopy_lower_accuracy_2.csv # Evaluation dataset
│   │   ├── 📄 WineQTcopy_lower_accuracy.csv # Evaluation dataset
├── 📁 infrastructure # This folder defines the modular components as IaC definitions
│   ├── 📂 aws # This folder contains aws infrastructure components
│   │   ├── 📄 ec2.tf # This file contains Training and Monitoring_Deployment_Registry Terraform EC2 instance definitions
│   │   ├── 📄 function.py # This file contains function that is used by lambda function component to trigger the training EC2 instance
│   │   ├── 📄 iam.tf # This file sets IAM permissions required by AWS vendor using Terraform definitions
│   │   ├── 📄 lambda_function.tf # This file contains Terraform lambda function definition 
│   │   ├── 📄 training-user-data.sh # This file contains script to install and configure packages, tools and files for EC2 Training instance during provisioning process
│   │   ├── 📄 user-data.sh # This file contains script to install and configure packages, tools and files for EC2 Monitoring_Deployment_Registry instance during provisioning process
│   ├── 📂 gcp # This folder contains gcp infrastructure components
│   │   ├── 📄 function.py # This file contains function to be used by GCP function component to trigger GCP compute instance
│   │   ├── 📄 google_cloud_compute # This file contains AWS EC2 instance mapped equivelant Google Cloud Compute defined with IaC definition
│   │   ├── 📄 google_cloud_function # This file contains AWS Lambda Function mapped equivelant Google Cloud Function defined with IaC definition
│   │   ├── 📄 google_cloud_storage # This file contains AWS S3 mapped equivelant Google Cloud Storage defined with IaC definition
│   │   ├── 📄 main.py # To run the function in google_cloud_function
│   │   ├── 📄 requirements.txt # Required libraries to run the main.py
├── 📁 script # Contains scripts that are used in the training and deployment stages of the pipeline
│   ├── 📄 deploy.py # This file serves the model with FastAPI Endpoint and implements rollback functionality
│   ├── 📄 train.py # This file preprocess and trains the model, implement validation gate and registers the model to MLflow
└── 📄 main.tf # This file installs and defines AWS and GCP in Terraform
```

## Deployment

The full pipeline requires cloud accounts and cannot run without them. 

### Prerequisites
------
- Terraform is installed https://developer.hashicorp.com/terraform/install
- An AWS account and GCP account for portability with IAM user permissions
- For GCP, enable required APIs
    - Cloud Storage: storage.googleapis.com 
    - Compute Engine: compute.googleapis.com 
    - Cloud Function: cloudfunction.googleapis.com
    - Cloud Build: cloudbuild.googleapis.com
    - Logging: logging.googleapis.com
    - IAM: iam.googleapis.com
    - Event Triggering: eventarc.googleapis.com and pubsub.googleapis.com
    - Secret Manager: secretmanager.googleapis.com
    - Resource Manager: cloudresourcemanager.googleapis.com
- Download the repository
- Open the project in Code Editor
- Change the project name and region based on your settings before provisioning

### Steps
-----
#### AWS
1. Install AWS CLI from https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
2. Set AWS credentials using https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html
3. Make sure the user has the right permissions
4. Navigate to `infrastructure/aws` folder
5. Run `Terraform init`then `terraform apply` answer 'yes' to the pop-up question
6. Check your AWS console
7. Navigate to S3 bucket component
8. Add the dataset, and training, and deployment to the `dataset/` and `scripts/` folders

#### GCP
1. Install GCP CLI from https://docs.cloud.google.com/sdk/docs/install-sdk
2. Set GCP credentials using https://docs.cloud.google.com/docs/authentication/provide-credentials-adc
3. Make sure the user has the right permissions
4. Navigate to `infrastructure/gcp` folder
5. Run `Terraform init`then `terraform apply` answer 'yes' to the pop-up question
6. Check your GCP console
The modular components must be provisioned
* In order to run both vendors, Run `terraform init`then `terraform apply` answer 'yes' to the pop-up question from the root folder.
