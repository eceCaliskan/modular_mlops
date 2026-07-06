import pickle
import time
import boto3
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score
import mlflow
from mlflow import MlflowClient
remote_server_uri = 'http://44.220.91.173:8080'  
mlflow.set_tracking_uri(remote_server_uri)
mlflow.set_experiment("wine-quality")


time.sleep(10)
ssm = boto3.client('ssm', region_name='us-east-1')
response = ssm.get_parameter(Name='/ml/input_file')
s3_path = response['Parameter']['Value']
bucket, key = s3_path.replace("s3://", "").split("/", 1)
old_champion = None
s3 = boto3.client('s3', region_name='us-east-1')
s3.download_file(bucket, key, '/tmp/input.csv')
df = pd.read_csv('/tmp/input.csv')

print(df.columns.tolist())
print(df)
client = MlflowClient()


def preprocess(df):
    df['label'] = (df['quality'] >= 6).astype(int)
    features = [
        'fixed acidity', 'volatile acidity', 'citric acid', 'residual sugar',
        'chlorides', 'free sulfur dioxide', 'total sulfur dioxide', 'density',
        'pH', 'sulphates', 'alcohol'
    ]
    X = df[features]
    y = df['label']
    return X, y


def train(X, y):
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    return model, accuracy, f1

def save_model(model, accuracy):
    model_path = '/tmp/model.pkl'
    with open(model_path, 'wb') as f:
        pickle.dump(model, f)

    s3 = boto3.client('s3', region_name='us-east-1')
    version = f"models/v_{accuracy:.4f}/model.pkl"
    s3.upload_file(model_path, 'modular-mlops-bucket', version)
    
def get_old_champion_details():
    try:
        old_champion = client.get_model_version_by_alias(
            "sk-learn-random-forest-reg-model",
            "champion"
        )
        old_run = mlflow.get_run(old_champion.run_id)
        old_accuracy = old_run.data.metrics.get("accuracy")
        old_f1 = old_run.data.metrics.get("f1score")
        print(f"Old champion — accuracy: {old_accuracy}, f1: {old_f1}")
        return old_accuracy, old_f1
    except Exception:
        old_champion = None
        return None, None

def register_model(f1, accuracy, model):
    # Logging a run
    with mlflow.start_run():
        mlflow.log_param("testsize", '0.2')
        mlflow.log_metric('f1score', f1)
        mlflow.log_metric('accuracy', accuracy)
        #alias champion tracks the latest version of the registered model in mlflow 
        mlflow.sklearn.log_model(
            sk_model=model,
            name="sklearn-model",
            registered_model_name="sk-learn-random-forest-reg-model",
        )
def set_model_as_champion():
    latest_version = client.get_registered_model("sk-learn-random-forest-reg-model").latest_versions[-1].version
    client.set_registered_model_alias(
        name="sk-learn-random-forest-reg-model",
        alias="champion",
        version=latest_version
    )

x,y = preprocess(df)
model, accuracy, f1 = train(x, y)
oldaccuracy, oldf1 = get_old_champion_details()
save_model(model, accuracy)

if old_champion is None or (oldaccuracy <= accuracy and oldf1 <= f1):
    register_model(f1, accuracy, model)
else:
    print(f"New model did not beat champion accuracy: {accuracy:.4f} vs {oldaccuracy:.4f}")


