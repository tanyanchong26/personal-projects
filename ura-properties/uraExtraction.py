import json
import pandas as pd
from onemapsg import OneMapClient
import awswrangler as wr
import boto3
import datetime as dt
import urllib.request
import yaml
import time

#%% Authentication

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)

#%% Get Token

accessKey = cred["ura_credentials"]["accessKey"]

def getToken(access_key):
    url = "https://www.ura.gov.sg/uraDataService/insertNewToken.action"
    hdr = { 'AccessKey' : access_key }

    req = urllib.request.Request(url, headers=hdr)
    response = urllib.request.urlopen(req)
    token = json.loads(response.read().decode("utf-8"))["Result"]
    
    return token

token = getToken(accessKey)

#%% Extract Data

def getData(access_key, token, batch):
    
    url = "https://www.ura.gov.sg/uraDataService/invokeUraDS?service=PMI_Resi_Transaction&batch={0}".format(batch)
    hdr = { 'AccessKey' : accessKey, 'Token' : token}
    req = urllib.request.Request(url, headers=hdr)
    response = urllib.request.urlopen(req)
    json_data = json.loads(response.read().decode("utf-8"))
    main_df = pd.DataFrame(json_data["Result"])
    main_df = main_df.explode("transaction")
    txn_df = main_df["transaction"].apply(lambda x:pd.Series(x))
    combined_df = pd.concat([main_df, txn_df], axis = 1)

    return combined_df

extractedDataList = []

for i in range(1,5):
    extractedDataList.append(getData(accessKey, token, i))
    time.sleep(3)


#%% Set Date Params

date_cutoff = (dt.datetime.strptime(dt.date.today().replace(month = dt.date.today().month - 1).strftime("%Y-%m-01"), 
                                   "%Y-%m-%d")).date()
    
#%% Combine Data

def dataCleanStage1(df_list, date_cutoff):
    df_total = pd.concat(df_list)
    df_total["month"] = pd.to_datetime(df_total["contractDate"], format = "%m%y").dt.date
    df_total = df_total[df_total["month"] >= date_cutoff]
    df_total.drop(columns=["transaction"], inplace=True)
    cols_to_numeric = ["x", "y", "area", "noOfUnits", "nettPrice", "price"]
    for i in cols_to_numeric:
        df_total[i] = df_total[i].astype(float)
    df_total["price"] = df_total["price"].astype("int64")

    return df_total

df_stage1 = dataCleanStage1(extractedDataList, date_cutoff)

#%% Extract Geo-Location

def geoLocExtract(DF, username, password):
    
    client = OneMapClient(username, password)
    
    unique_projects = list(set(DF["project"]))

    projects_geoloc = []

    for i in unique_projects:
        searched_results = client.search(i)["results"]
        if len(searched_results)>0:
            projects_geoloc.append(searched_results[0])
        else:
            projects_geoloc.append(None)

    geoloc_df = pd.DataFrame([(i,j["LATITUDE"], j["LONGITUDE"]) if j is not None else (i,None, None) \
                  for i,j in zip(unique_projects, projects_geoloc)],
                 columns = ["project", "latitude", "longitude"])
    geoloc_df["latitude"] = geoloc_df["latitude"].astype(float)
    geoloc_df["longitude"] = geoloc_df["longitude"].astype(float)
    geoloc_df = geoloc_df[pd.notnull(geoloc_df["latitude"])]
    
    return geoloc_df

df_geoloc = geoLocExtract(df_stage1, 
                          "tanyanchong91@gmail.com", 
                          cred["onemap_credentials"]["password"])


#%% Join

def dataCleanStage2(df, df_geoloc):
    df_final = pd.merge(df, df_geoloc, left_on = "project", right_on="project", how = "left")
    df_final.drop(columns = "contractDate", inplace=True)
    df_final = df_final[["street", "project", "marketSegment",
                         "latitude", "longitude", "area", "floorRange",
                         "noOfUnits", "month", "typeOfSale",
                         "price", "propertyType", "district",
                         "typeOfArea", "tenure", "nettPrice"]]
    
    return(df_final)

df_final = dataCleanStage2(df_stage1, df_geoloc)


#%% Write to S3

def s3write(df):
    session = boto3.session.Session(
        aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
        aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
        )
    
    wr.s3.to_parquet(
        df=df_final,
        path="s3://ura-properties/",
        dataset=True,
        mode="overwrite_partitions",
        boto3_session=session,
        partition_cols=["month"]
        )

s3write(df_final)
