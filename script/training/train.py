import pickle
import time
import boto3
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score
import mlflow
from mlflow import MlflowClient
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)
client = None

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
        logging.info(f"TRAINING - SUCCESS: ID of Instance Monitoring_Deployment_Registry successfully retrieved. Instance ID = {instance_ids[0]}")
        return instance_ids[0]
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure retrieving the ID of Monitoring_Deployment_Registry instance. Exception: {e}")

'''
    This method is responsible for preprocessing the dataset to convert them to binary
    Putting into account the quality of the wine with the df['quality'] >= 7
'''
def preprocess(df):
    try:
        df['label'] = (df['quality'] >= 7).astype(int)
        features = [
            'fixed acidity', 'volatile acidity', 'citric acid', 'residual sugar',
            'chlorides', 'free sulfur dioxide', 'total sulfur dioxide', 'density',
            'pH', 'sulphates', 'alcohol'
        ]
        features_df = df[features]
        labels_df = df['label']
        logging.info(f"TRAINING - SUCCESS: Successfully converted the dataset to binary during preprocessing")
        return features_df, labels_df
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure converting the dataset to binary during preprocessing. Exception: {e}")

'''
    This method is responsible for stopping the Training EC2 instance at the end of the training
'''
def stop_training_instance():
    try:
        ec2 = boto3.client("ec2", region_name="us-east-1")
        response = ec2.describe_instances(
        Filters=[
            {
                "Name": "tag:Purpose",
                "Values": ["Training"]
            },
            {"Name": "instance-state-name", "Values": ["running"]}   
        ]
        )
        instance_ids = [
            instance["InstanceId"]
            for reservation in response["Reservations"]
            for instance in reservation["Instances"]
        ]
        ec2.stop_instances(InstanceIds=instance_ids)
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure stopping the Training EC2 instance. Exception: {e}")

'''
    This method is responsible for training the dataset and return the model, accuracy and f1 scores
'''
def train(features_df, labels_df):
    try:
        features_df_train, features_df_test, labels_df_train, labels_df_test = train_test_split(features_df, labels_df, test_size=0.2, random_state=42)
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(features_df_train, labels_df_train)
        labels_df_pred = model.predict(features_df_test)
        accuracy = accuracy_score(labels_df_test, labels_df_pred)
        f1 = f1_score(labels_df_test, labels_df_pred)
        logging.info(f"TRAINING - SUCCESS: Successfully trained the dataset. Model: {model}, Accuracy: {accuracy}, F1: {f1}")
        return model, accuracy, f1
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure training the dataset. Exception: {e}")

'''
    This method is responsible for saving the model to S3 bucket
'''
def save_model(model, accuracy):
    try:
        model_path = '/tmp/model.pkl'
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)
        s3 = boto3.client('s3', region_name='us-east-1')
        version = f"models/v_{accuracy:.4f}/model.pkl"
        s3.upload_file(model_path, 'modular-mlops-bucket', version)
        logging.info(f"TRAINING - SUCCESS: Successfully saved the model to S3 bucket. Version: {version}")
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure saving the model to S3 bucket. Exception: {e}")
    
'''
    This method is responsible for returning the current champion in MLflow with its metrics
'''
def get_old_champion_details():
    try:
        client = set_up_mlflow()
        old_champion = client.get_model_version_by_alias(
            "sk-learn-random-forest-reg-model",
            "champion"
        )
        old_run = mlflow.get_run(old_champion.run_id)
        old_accuracy = old_run.data.metrics.get("accuracy")
        old_f1 = old_run.data.metrics.get("f1score")
        logging.info(f"TRAINING - SUCCESS: Champion successfully returned with metrics accuracy: {old_accuracy}, f1 score: {old_f1}.")
        return old_accuracy, old_f1, old_champion
    except Exception as e:
        logging.info(f"TRAINING - INFO: No champion model is currently stored in MLflow. Exception: {e}")
        old_champion = None
        return None, None, old_champion

'''
    This method is used for registering the given model to MLflow 
'''
def register_model(f1, accuracy, model):
    try:
        with mlflow.start_run():
            mlflow.log_param("testsize", '0.2')
            mlflow.log_metric('f1score', f1)
            mlflow.log_metric('accuracy', accuracy)
            mlflow.sklearn.log_model(
                sk_model=model,
                name="sklearn-model",
                registered_model_name="sk-learn-random-forest-reg-model",
            )
        logging.info(f"TRAINING - SUCCESS: Current model successfully registered to MLflow. Accuracy: {accuracy}, F1: {f1_score}")
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Current model couldn't get registered to MLflow. Exception: {e}")
        old_champion = None
        return None, None, old_champion   
'''
    This method is responsible for setting the current model alias to champion
'''
def set_model_as_champion():
    try:
        client = set_up_mlflow()
        latest_version = client.get_registered_model("sk-learn-random-forest-reg-model").latest_versions[-1].version
        # Alias champion tracks the latest version of the registered model in mlflow 
        client.set_registered_model_alias(
            name="sk-learn-random-forest-reg-model",
            alias="champion",
            version=latest_version
        )
        logging.info("TRAINING - SUCCESS: The current model alias successfully set to champion.")
    except Exception as e:
        logging.error(f"TRAINING - ERROR: The current model alias couldn't be set to champion. Exception: {e}")

'''
    This method is responsible for comparing the new model metrics with the old model metrics
    Core mechanism of the validation gate
'''
def validation_gate(current_champion, old_model_accuracy, new_model_accuracy, old_model_f1, new_model_f1):
    try:
        if current_champion is None or (old_model_accuracy <= new_model_accuracy and old_model_f1 <= new_model_f1):
            logging.info(f"TRAINING - SUCCESS: The new model performed better than the current champion and passed the validation gate. Old Accuracy: {old_model_accuracy}, Old F1: {old_model_f1}, New Accuracy: {new_model_accuracy}, New F1: {new_model_f1}")
            return True
        else:
            logging.info(f"TRAINING - INFO: The new model performed worse than current champion and failed the validation gate. Old Accuracy: {old_model_accuracy}, Old F1: {old_model_f1}, New Accuracy: {new_model_accuracy}, New F1: {new_model_f1}")
            return False
    except Exception as e:
        logging.error(f"TRAINING - ERROR: The validation gate failed to run. Exception: {e}")
    
'''
    This method is responsible for setting up the MLflow experiment
'''
def set_up_mlflow():
    try:
        remote_server_uri = get_monitoring_deployment_registry_instance()
        mlflow.set_tracking_uri(f'http://{remote_server_uri}:8080')
        mlflow.set_experiment("wine-quality")
        time.sleep(10)
        logging.info(f"TRAINING - INFO: MLflow Successfully set uo")
        return MlflowClient(tracking_uri=f'http://{remote_server_uri}:8080')
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure setting up MLFlow server. Exception: {e}")

'''
    This method is responsible for downloading the train.py file from S3 bucket 
'''
def download_training_script():
    try:
        ssm = boto3.client('ssm', region_name='us-east-1')
        response = ssm.get_parameter(Name='/ml/input_file')
        s3_path = response['Parameter']['Value']
        bucket, key = s3_path.replace("s3://", "").split("/", 1)
        s3 = boto3.client('s3', region_name='us-east-1')
        s3.download_file(bucket, key, '/tmp/input.csv')
        logging.info(f"TRAINING - SUCCESS: Successfully downloaded training script from S3 bucket.")
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure downloading training script from S3 bucket. Exception: {e}")

'''
    This method is responsible for setting up the training pipeline
'''
def training_pipeline():
    try:
        download_training_script()
        df = pd.read_csv('/tmp/input.csv')
        print(df.columns.tolist())
        print(df)
        features_df, labels_df = preprocess(df)
        model, new_model_accuracy, new_model_f1 = train(features_df, labels_df)
        old_model_accuracy, old_model_f1, current_champion = get_old_champion_details()
        save_model(model, new_model_accuracy)
        if validation_gate(current_champion, old_model_accuracy, new_model_accuracy, old_model_f1, new_model_f1) == True:
            register_model(new_model_f1, new_model_accuracy, model)
            time.sleep(10) # Fixing the error of Exception: Registered Model with name=sk-learn-random-forest-reg-model not found 
            set_model_as_champion()
        else:
            print(f"New model did not beat champion accuracy: {new_model_accuracy:.4f} vs {old_model_accuracy:.4f}")
        stop_training_instance()
        logging.info(f"TRAINING - SUCCESS: Training pipeline successfully run.")
    except Exception as e:
        logging.error(f"TRAINING - ERROR: Failure running the pipeline. Exception: {e}")

training_pipeline()