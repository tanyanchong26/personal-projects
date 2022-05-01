import requests
import boto3
import json
from datetime import datetime
import yaml

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)

def read_covid_current_us():
    
    # Retrieve JSON Data from API
    
    url = "https://api.covidtracking.com/v1/us/current.json"
    received = requests.get(url)
    received_json = received.json()
    
    # S3 Authentication
    
    s3 = boto3.resource(
        's3',
        aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
        aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
    )
    
    # Write to S3
    
    date_read = str(received_json[0]["date"])
    date_read_format = datetime.strptime(date_read, "%Y%m%d").strftime("%Y-%m-%d")
    filename = "all/date=" + date_read_format + ".json"
    obj = s3.Object("covid-tracking-api",filename) 
    obj.put(Body=json.dumps(received_json))
    
read_covid_current_us()

def read_covid_current_states():
    
    # Retrieve JSON Data from API
    
    url = "https://api.covidtracking.com/v1/states/current.json"
    received = requests.get(url)
    received_json = received.json()
    
    # S3 Authentication
    
    s3 = boto3.resource(
        's3',
        aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
        aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
    )
    
    # Write to S3
    
    date_read = str(received_json[0]["date"])
    date_read_format = datetime.strptime(date_read, "%Y%m%d").strftime("%Y-%m-%d")
    filename = "states/date=" + date_read_format + ".json"
    obj = s3.Object("covid-tracking-api",filename) 
    obj.put(Body=json.dumps(received_json))

read_covid_current_states()



