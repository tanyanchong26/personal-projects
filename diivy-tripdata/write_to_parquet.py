import os
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import json
import boto3
import awswrangler as wr
import re
import yaml

#from google.cloud import storage
#from google.oauth2 import service_account

#%% Set Directory

os.chdir(os.path.dirname(__file__))

#%% Extract Credentials

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)

#%% Google Cloud Authentication

# key_loc = 'bike-share-357913-10ecc769f77a-gcloud-key.json'

# with open(key_loc) as source:
#     info = json.load(source)

# storage_credentials = service_account.Credentials.from_service_account_info(info)
# storage_client = storage.Client(credentials=storage_credentials)

#%% AWS Authentication

s3 = boto3.session.Session(
    aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
    aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
    )

#%% List of Files

csv_files = os.listdir("bike-share/")

#%% Upload to Google Cloud

# for file in csv_files:
#     df = pd.read_csv("bike-share/" + file)
#     df["started_at"] = pd.to_datetime(df["started_at"])
#     df["ended_at"] = pd.to_datetime(df["ended_at"])
#     partition_name = re.findall("^(\d+)-.*", file)[0]
    
#     df["month"] = pd.to_datetime("{0}-{1}".format(
#         partition_name[0:4], partition_name[4:])
#         ).date()
    
#     bucket = storage_client.get_bucket(bucket_name)
#     df.to_parquet("gs://{0}/raw".format(bucket_name),
#                   partition_cols=["month"],
#                   storage_options={"token": key_loc})
    
#%% Upload to Google Cloud
    
for file in csv_files:
    df = pd.read_csv("bike-share/" + file)
    df["started_at"] = pd.to_datetime(df["started_at"])
    df["ended_at"] = pd.to_datetime(df["ended_at"])
    partition_name = re.findall("^(\d+)-.*", file)[0]
    
    df["month"] = pd.to_datetime("{0}-{1}".format(
        partition_name[0:4], partition_name[4:])
        ).date()
    
    wr.s3.to_parquet(
        df=df,
        path="s3://diivy-trip-data-bike-share/raw",
        dataset=True,
        mode="overwrite_partitions",
        partition_cols = ["month"],
        boto3_session=s3
        )
    