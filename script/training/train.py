import time
import boto3
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report

time.sleep(10)
ssm = boto3.client('ssm', region_name='us-east-1')
response = ssm.get_parameter(Name='/ml/input_file')
s3_path = response['Parameter']['Value']
bucket, key = s3_path.replace("s3://", "").split("/", 1)

s3 = boto3.client('s3', region_name='us-east-1')
s3.download_file(bucket, key, '/tmp/input.csv')
df = pd.read_csv('/tmp/input.csv')

print(df.columns.tolist())
print(df)


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
    return model, accuracy

x,y = preprocess(df)
m, a = train(x, y)
print(m,a)