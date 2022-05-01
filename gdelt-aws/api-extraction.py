import pandas as pd
from datetime import date, timedelta
import csv
import urllib
import gzip
from io import StringIO
import re
import boto3
import awswrangler as wr
import yaml

#%% Extract Credentials

with open(r'credentials.yaml') as file:
    cred = yaml.load(file, Loader=yaml.FullLoader)
    
#%% Functions

def extractLastFile():

    filelistUrl = "http://data.gdeltproject.org/gdeltv3/ggg/MASTERFILELIST.TXT"
    filelistResponse = urllib.request.urlopen(filelistUrl)
    filelistReader = csv.reader([l.decode('utf-8') for l in filelistResponse.readlines()])

    filelist = []

    for i in filelistReader:
        filelist.extend(i)

    return(filelist[-1])


def checkLatestFile():

    currentLatestDate = (date.today() - timedelta(days=1)).strftime("%Y%m%d")
    latestFileNameDate = re.findall("ggg/(.*).ggg", extractLastFile())[0]

    if currentLatestDate == latestFileNameDate:
        return True
    else:
        return False

def extractLatestData():

    if checkLatestFile()==True:

        latestFile = extractLastFile()

        with urllib.request.urlopen(latestFile) as response:
            with gzip.GzipFile(fileobj=response) as uncompressed:
                fileContent = uncompressed.read()

        contentDecoded = fileContent.decode('utf8')
        del fileContent

        filename = re.findall("ggg/(.*).gz", latestFile)[0]
        contentChunks = []
        contentFlow = pd.read_json(StringIO(contentDecoded), lines = True, chunksize=1000)

        for c in contentFlow:
            contentChunks.append(c)

        del contentDecoded

        contentDF = pd.concat(contentChunks)
        del contentFlow
        del contentChunks

        contentDF["IngestionTimestamp"] = pd.Timestamp.now()
        contentDF["DateTime"] = contentDF["DateTime"].dt.tz_localize(None)
        contentDF["Adm2Code"] = contentDF["Adm2Code"].astype(str)
        contentDF["Adm2Code"] = [None if i == "nan" else i for i in contentDF["Adm2Code"]]
        contentDF["DomainCountryCode"] = contentDF["DomainCountryCode"].astype(str)
        contentDF["DomainCountryCode"] = [None if i == "nan" else i for i in contentDF["DomainCountryCode"]]

        return(contentDF)

def writeParquet():

    if checkLatestFile()==True:

        dataset = extractLatestData()
        filename = re.findall("ggg/(.*).ggg", extractLastFile())[0]

        s3 = boto3.session.Session(
            aws_access_key_id=cred["aws_credentials"]["aws_access_key_id"],
            aws_secret_access_key=cred["aws_credentials"]["aws_secret_access_key"]
            )

        wr.s3.to_parquet(
            df=dataset,
            path="s3://gdelt-ggg-aws/{0}".format("ggg_" + filename),
            dataset=True,
            mode="overwrite",
            boto3_session=s3
            )

writeParquet()
