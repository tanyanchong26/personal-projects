# Packages ----

library(tidyverse)
library(odbc)
library(DBI)
library(dbplyr)

# Database Connection ----

conn <- DBI::dbConnect(odbc::odbc(),
                       Driver="SnowflakeDSIIDriver",
                       Server="tj86262.ap-southeast-1.snowflakecomputing.com",
                       Database="URAPROPERTIESDB",
                       SCHEMA="PUBLIC",
                       UID=Sys.getenv("SNOWFLAKE_UID"),
                       PWD=Sys.getenv("SNOWFLAKE_PASSWORD"),
                       WAREHOUSE="URAPROPERTIESDWH"
)

## Extract Transactions  ----

transactions <- tbl(conn, "URA_PRIVATE") %>%
  collect(.)

## Extract Polyons ----

polygons <- tbl(conn, "URA_POLYGON") %>%
  collect(.)

## Save as CSV ----

write_csv(transactions, "transactions.csv", quote = "all")
write_csv(polygons, "polygons.csv", quote = "all")

## Disconnect ----

dbDisconnect(conn)