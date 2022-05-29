library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinythemes)
library(tidyverse)
library(plotly)
library(httr)
library(rjson)
library(jsonlite)
library(glue)
library(magrittr)
library(slider)
library(tidymodels)
library(DT)

### Parameters List

supportedCurrenciesURL <- "https://api.coingecko.com/api/v3/simple/supported_vs_currencies"
supportedCurrenciesResult <- GET(supportedCurrenciesURL)
supportedCurrencies <- rjson::fromJSON(rawToChar(supportedCurrenciesResult$content))

coinsDetailsURL <- "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=250&page=1"
coinsDetailsResult <- GET(coinsDetailsURL)
coinsDetails <- jsonlite::fromJSON(rawToChar(coinsDetailsResult$content))
coinDetailsNameList <- coinsDetails %>%
  select(name, symbol) %>%
  mutate(
    Name = str_c(name, " (",str_to_upper(symbol),")", sep="")
  ) %>%
  pull(Name)