library(leaflet)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)
library(shiny)
library(shinydashboard)

schools <- c("Anglican High School",
             "Catholic High School",
             "CHIJ St Nicholas Girls Secondary School",
             "Chung Cheng High School (Main)",
             "Dunman High School",
             "Hwa Chong Institution",
             "Maris Stella High School",
             "Nan Hua High School",
             "Nanyang Girls High School",
             "River Valley High School")

postal <- c("487012", "579767", "569405", "439012",
            "436895", "269734", "368051", "129956",
            "288683", "649961")

api_func <- function(search_val){
  res = GET(glue("https://developers.onemap.sg/commonapi/search?searchVal={search_val}&returnGeom=Y&getAddrDetails=Y&pageNum=1"))
  return(tibble(fromJSON(rawToChar(res$content))$results)[, c("LATITUDE", "LONGITUDE")])
  
}

dataset <- tibble(schools, postal) %>%
  mutate(coordinates = map(postal, ~api_func(.x))) %>%
  unnest(coordinates) %>%
  mutate_at(vars(LATITUDE, LONGITUDE), ~as.numeric(.)) %>%
  group_by(schools) %>%
  mutate(
    entry_order = row_number()
  ) %>%
  ungroup() %>%
  filter(entry_order==1) %>%
  select(-entry_order)




server <- function(session, input, output){
  
  output$map <- renderLeaflet({
    
    leaflet(dataset) %>% 
      setView(103.8198, 1.3521, zoom = 12) %>%
      addProviderTiles(providers$Stamen.TonerLines,
                       options = providerTileOptions(opacity = 0.35)) %>%
      addProviderTiles(providers$Stamen.TonerLabels) %>%
      addCircleMarkers(~LONGITUDE, ~LATITUDE, popup = ~as.character(schools), label = ~as.character(schools), fillOpacity = 0.8,
                       radius = 5, stroke=FALSE, color = "navy")
  })
  
}

ui <- dashboardPage(
  dashboardHeader(title = "Yan Chong x Mabel"),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      column(12,
             leafletOutput("map", height = 1000)
             )
    )
  )
)

shinyApp(ui, server)