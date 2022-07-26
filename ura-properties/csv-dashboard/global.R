# Packages ----

library(tidyverse)
library(lubridate)
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinythemes)
library(leaflet)
library(leaflet.extras)
library(plotly)
library(jsonlite)
library(sf)

# Read CSV ----

transactions_orig <- read_csv("transactions.csv", show_col_types = FALSE)

polygons <- read_csv("polygons.csv", show_col_types = FALSE)

# Input Parameters ----

## Year ----

years <- transactions_orig %>%
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

prop_type <- transactions_orig %>%
  distinct(PROPERTY_TYPE) %>%
  collect(.) %>%
  pull(.)
  
## Polygons ----

polygons <- polygons %>%
  filter(!is.na(GEOJSON)) %>%
  collect(.)