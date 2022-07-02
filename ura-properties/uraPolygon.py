import requests
import pandas as pd
import snowflake.connector
import snowflake.connector.pandas_tools
import yaml
import os

os.chdir("/home/tanyanchong/OneDrive/Documents/Git/personal-projects/ura-properties")

#%% Authentication

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)

#%% Get Token

email = "tanyanchong91@gmail.com"
password = cred["onemap_credentials"]["password"]
url = "https://developers.onemap.sg/privateapi/auth/post/getToken"
input_ = {"email": email, "password":password}
token = requests.post(url, json=input_)
token = token.json()["access_token"]

#%% Getting Planning Area Polygons

url = "https://developers.onemap.sg/privateapi/popapi/getAllPlanningarea?token=%s&year=2014" %token
planning_areas = requests.get(url).json()
planning_areas_df = pd.DataFrame(planning_areas)
planning_areas_df.columns = [i.upper() for i in planning_areas_df.columns]

#%% Load to Snowflake

conn = snowflake.connector.connect(
                user=cred["snowflake_credentials"]["user"],
                password=cred["snowflake_credentials"]["password"],
                account=cred["snowflake_credentials"]["account"],
                warehouse="URAPROPERTIESDWH",
                database="URAPROPERTIESDB",
                schema="PUBLIC"
                )

snowflake.connector.pandas_tools.write_pandas(
    conn = conn,
    df = planning_areas_df,
    table_name = "URA_POLYGON",
    )