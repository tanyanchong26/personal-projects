# Packages ----

library(tidyverse)
library(lubridate)
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinythemes)
library(odbc)
library(DBI)
library(dbplyr)
library(leaflet)
library(leaflet.extras)
library(plotly)
library(jsonlite)
library(sf)

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

# Input Parameters ----

## Year ----

years <- tbl(conn, "URA_PRIVATE") %>%
  summarise(
    start_month = min(MONTH),
    end_month = max(MONTH)
    ) %>%
  collect(.)

start_year <- year(years$start_month)
end_year <- year(years$end_month)

## Month ----

month_list <- month.abb

## Property Type ----

prop_type <- tbl(conn, "URA_PRIVATE") %>%
  distinct(PROPERTY_TYPE) %>%
  collect(.) %>%
  pull(.)
  
## Polygons ----

polygons <- tbl(conn, "URA_POLYGON") %>%
  filter(!is.na(GEOJSON)) %>%
  collect(.)