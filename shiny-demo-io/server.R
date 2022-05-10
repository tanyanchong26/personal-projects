server <- function(session, input, output){

  
  observeEvent(input$name, {
    name <- isolate(input$name)
    output$textOutputResult <- renderUI({
      if (name==""){
        ""
      } else {
        paste0(name, " is the prettiest of them all ...")
      }
    })
  })
  
  observeEvent(input$life_story, {
    life_story <- isolate(input$life_story)
    output$textAreaOutputResult <- renderUI({
      if (life_story==""){
        ""
      } else {
        paste0("Stop your grandmother's story ....")
      }
    })
  })
  
  observeEvent(input$generateButton, {
    category <- isolate(input$category)
    dateRange <- isolate(input$tickerDateRange)
    startDate <- dateRange[1]
    endDate <- dateRange[2]
    if (category=="Forex"){
      forexFrom <- isolate(input$from_forex)
      forexTo <- isolate(input$to_forex)
      forexInput <- paste0(forexFrom,"/",forexTo)
      forexResults <- getSymbols(forexInput,src='oanda',auto.assign=FALSE,
                                 from = startDate, to = endDate) %>%
        tk_tbl(., rename_index="Date")
      dateScaffold <- tibble(Date = seq(startDate, endDate, by = "1 day"))
      output$chartOutputResult <- renderPlotly({
        dateScaffold %>%
        left_join(forexResults, by=c("Date")) %>%
        fill(names(.), .direction="down") %>%
        plot_ly(., x=~Date, y=~eval(str2expression(last(names(.)))),
                type = 'scatter', mode = 'lines',
                hovertemplate = ~paste0(
                  "Pair: ", forexInput, "<br>",
                  "Price: ", eval(str2expression(last(names(.)))),
                  "<extra></extra>"
                ),
                textposition = "outside",
                cliponaxis = FALSE) %>%
        layout(
          yaxis = list(
            title = "Price"
          )
        )
      })
    } else if (category == "Equity"){
        tickerInput <- isolate(input$ticker)
        tickerResults <- getSymbols(tickerInput,src='yahoo',auto.assign=FALSE,
                                   from = startDate, to = endDate) %>%
          tk_tbl(., rename_index="Date")
        dateScaffold <- tibble(Date = seq(startDate, endDate, by = "1 day"))
        output$chartOutputResult <- renderPlotly({
          dateScaffold %>%
            left_join(tickerResults, by=c("Date")) %>%
            fill(names(.), .direction="down") %>%
            plot_ly(., x=~Date, y=~eval(str2expression(last(names(.)))),
                    type = 'scatter', mode = 'lines',
                    hovertemplate = ~paste0(
                      "Ticker: ", tickerInput, "<br>",
                      "Price: ", eval(str2expression(last(names(.)))),
                      "<extra></extra>"
                    ),
                    textposition = "outside",
                    cliponaxis = FALSE) %>%
            layout(
              yaxis = list(
                title = "Price"
              )
            )
        })
      
      }
  })
  
  observeEvent(input$generateHistogram, {
    mean <- isolate(input$mean)
    sd <- isolate(input$standev)
    obs <- isolate(input$obs)
    rng <- isolate(input$rng)
    rngStart <- rng[1]
    rngEnd <- rng[2]
    
    normData <- rnorm(n = obs, mean, sd)
    normDataFiltered <- normData[which(normData>= rngStart & normData <= rngEnd, arr.ind = TRUE)]
    
    output$histogram <- renderPlot({
      ggplot(data=NULL, aes(x=normDataFiltered)) +
        geom_histogram(bins = 20) +
        theme_economist() +
        labs(
          x = "Bins",
          y = "Count"
        )
    })
      
  })
  
  observeEvent(input$triggerSearch, {
    searchText <- isolate(input$search)
    searchTextInput <- str_replace_all(searchText," ","+")
    apiAddress <- glue("https://developers.onemap.sg/commonapi/search?searchVal={searchTextInput}&returnGeom=Y&getAddrDetails=Y")
    apiResult <- GET(apiAddress)
    apiResultDecoded <- fromJSON(rawToChar(apiResult$content))$results
    
    labelContent <- function(address, latitude, longitude){
      paste("Address: ", address, "</br>",
            "Latitude: ", latitude, "</br>",
            "Longitude: ", longitude, "</br>"
      ) %>% lapply(HTML)
    }
    
    if (length(apiResultDecoded)>=1){
      output$map <- renderLeaflet({
        apiResultDecoded %>%
          mutate_at(vars(LATITUDE,LONGITUDE), ~as.numeric(.)) %>%
          mutate(labelBox = pmap(list(ADDRESS, LATITUDE, LONGITUDE), labelContent)) %>%
          unnest(labelBox) %>%
          leaflet() %>%
          addTiles() %>%
          addMarkers(lng = ~LONGITUDE, lat = ~LATITUDE, label = ~labelBox)
      })
      
    output$searchOutcome <- renderText({
      "Search Success!"
    })
    
    output$searchTable <- renderDataTable(server = FALSE, {
      apiResultDecoded %>%
        datatable(extensions = 'Buttons',
                  options = list(pageLength = 4, dom = "Bfrtip",
                                 buttons = list(
                                   "copy",
                                   list(extend = "csv", filename = "address"),
                                   list(extend = "excel", filename = "address"),
                                   list(extend = "pdf", filename = "address")
                                 ),
                                 ordering = FALSE,
                                 paging = TRUE),
                  rownames = FALSE) %>%
        formatStyle(columns = colnames(.), fontSize = '50%')
    })
    
    } else if (length(apiResultDecoded)==0) {
      output$map <- renderLeaflet({
        leaflet() %>%
          addTiles() %>%
          addMarkers(lng = 103.851959, lat = 1.290270, label = "Singapore")
      })
      
      output$searchOutcome <- renderText({
        "Search Failed!"
      })
    }
    
  })
  
  rv <- reactiveValues(read_tbl = data.frame())
  
  observeEvent(req(input$read, input$upload_path), {
    
    ingested_file <- isolate(input$upload_path)
    header <- isolate(input$header)
    tbl <- read.csv(ingested_file$datapath, header = as.logical(header))
    rv$read_tbl <- tbl
    
    output$data_preview <- renderDataTable(server = FALSE, {
      datatable(tbl, 
                class = "table-bordered table-condensed",
                extensions = 'Buttons',
                options = list(pageLength = 10, dom = "Bfrtip",
                               buttons = list(
                                 "copy",
                                 list(extend = "csv", filename = "file", title=NULL),
                                 list(extend = "excel", filename = "file", title=NULL)
                               ),
                               ordering = FALSE,
                               paging = TRUE,
                               scrollX = TRUE),
                rownames=FALSE)
    })
  })
  

}

