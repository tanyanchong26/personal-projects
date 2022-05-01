import urllib
import pandas as pd
from datetime import datetime
import json
import calendar
import ast
import time
import awswrangler as wr
import boto3
import yaml

#%% Extract Credentials

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)

#%% Extract Currencies Supported

url = "https://api.coingecko.com/api/v3/simple/supported_vs_currencies"

with urllib.request.urlopen(url) as response:
    supportedCurrencies = ast.literal_eval(response.read().decode("utf-8"))

#%% List Coins Supported

listofCoins = {"btc":"bitcoin", "usdc":"usd-coin", "eth":"ethereum"}

#%% Set Time Parameters

def time_params():
    currentDateTime = datetime.utcnow()
    currentDateTimeHour = currentDateTime.hour
    currentDateTimeHourEnd = currentDateTime.replace(hour=currentDateTimeHour-1, 
                                                               minute = 59,
                                                               second = 59,
                                                               microsecond = 0)
    currentDateTimeHourStart = currentDateTime.replace(hour=currentDateTimeHour-1, 
                                                               minute = 0,
                                                               second = 0,
                                                               microsecond = 0)
    currentDateTimeHourStartUNIX = calendar.timegm(currentDateTimeHourStart.utctimetuple())
    currentDateTimeHourEndUNIX = calendar.timegm(currentDateTimeHourEnd.utctimetuple())

    return(currentDateTimeHourStartUNIX, currentDateTimeHourEndUNIX)


#%% Set data extraction

def dataExtraction(coin, currency, time_params):
    coinId = listofCoins[coin]
    startTime = time_params[0]
    endTime = time_params[1]

    url = "https://api.coingecko.com/api/v3/coins/{0}/market_chart/range?vs_currency={1}&from={2}&to={3}"\
        .format(coinId, currency, startTime, endTime)

    with urllib.request.urlopen(url) as response:
        extractedDataJSON = json.loads(response.read().decode("utf-8"))

    timestamp = [i[0] for i in extractedDataJSON["prices"]]
    date = [datetime.fromtimestamp(i[0]/1000, None).date() for i in extractedDataJSON["prices"]]
    prices = [i[1] for i in extractedDataJSON["prices"]]
    marketCaps = [i[1] for i in extractedDataJSON["market_caps"]]
    volumes = [i[1] for i in extractedDataJSON["total_volumes"]]

    combinedResult = [(coinId, coin, currency,i,j,k,m,n) for i,j,k,m,n in \
                      zip(date, timestamp, prices, marketCaps, volumes)]
    combinedResultDF = pd.DataFrame(combinedResult, 
             columns = ["coin_id", "coin", "currency", "date", "timestamp", "price", 
                        "market_cap", "volume_24h"])

    combinedResultDF = combinedResultDF.astype({
        "coin_id": "str",
        "coin": "str",
        "currency": "str",
        "date":"str",
        "timestamp":"int64",
        "price":"float64",
        "market_cap":"float64",
        "volume_24h":"float64"
        })

    return(combinedResultDF)

#%% Execute Data Extraction

s3 = boto3.session.Session(
    aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
    aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
    )

def s3write(s3session):
    for i in listofCoins.keys():
        for j in supportedCurrencies:
            extractedResult = dataExtraction(i, j, time_params())
            wr.s3.to_parquet(
                df=extractedResult,
                path="s3://cryptoprices-coingecko/prices",
                dataset=True,
                mode="overwrite",
                boto3_session=s3session,
                partition_cols=["coin", "currency","date"]
                )
            time.sleep(1)

s3write(s3)
