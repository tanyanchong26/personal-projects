server <- function(session, input, output){
  
  output$remarks <- renderText({
"The MA periodicity is determined by the parameter, Period (Days). \n
Period (Days) = 1 ~ Periodicity = 5 mins 
1 < Period (Days) <= 90 ~ Periodicity = 1 hour 
Period (Days) > 90 ~ Periodicity = 1 day "
  })
  
  
  observeEvent(input$run,{
    daysParam <- isolate(input$period)
    currencyParam <- isolate(input$currency)
    coinParam <- isolate(input$coin)
    coinActualParam <- str_split(coinParam, "[[:space:]]\\(")[[1]][1]
    benchmarkCoinParam <- "bitcoin"
    MA1Param <- isolate(input$ma1)
    MA2Param <- isolate(input$ma2)
    coinParamId <- coinsDetails %>%
      filter(name == coinActualParam) %>%
      select(id) %>%
      pull(id)
    timeGranularity <- if (daysParam==1){
      "mins"
    } else if (daysParam <= 90) {
      "hours"
    } else {
      "days"
    }
    
    pricesExtraction <- function(coinParam, currencyParam, daysParam){
      marketURL <- glue("https://api.coingecko.com/api/v3/coins/{coinParam}/market_chart?vs_currency={currencyParam}&days={daysParam}")
      marketURLResult <- GET(marketURL)
      marketURL <- jsonlite::fromJSON(rawToChar(marketURLResult$content))
      
      prices <- as_tibble(marketURL$prices) %>%
        set_colnames(., c("timestamp", "price")) %>%
        mutate_at(vars(timestamp), ~as.POSIXct(./1000, origin = "1970-01-01")) %>%
        distinct()
      
      marketCaps <- as_tibble(marketURL$market_caps) %>%
        set_colnames(., c("timestamp", "market_cap")) %>%
        mutate_at(vars(timestamp), ~as.POSIXct(./1000, origin = "1970-01-01")) %>%
        distinct()
      
      volume <- as_tibble(marketURL$total_volumes) %>%
        set_colnames(., c("timestamp", "total_volume")) %>%
        mutate_at(vars(timestamp), ~as.POSIXct(./1000, origin = "1970-01-01")) %>%
        distinct()
      
      completeData <- prices %>%
        inner_join(marketCaps, by=c("timestamp")) %>%
        inner_join(volume,by=c("timestamp")) 
      
      return(completeData)
    }
    
    coinData <- pricesExtraction(coinParamId, currencyParam, daysParam)
    benchmarkData <- pricesExtraction(benchmarkCoinParam, currencyParam, daysParam)
    
    output$priceChart <- renderPlotly({
      priceChart <- coinData %>%
        mutate(price_MA1 = slide_dbl(price, mean, .before = MA1Param, .after = 0)) %>%
        mutate(price_MA2 = slide_dbl(price, mean, .before = MA2Param, .after = 0)) %>%
        plot_ly(
          x = ~timestamp,
          y = ~price,
          name = "Price",
          type = "scatter",
          mode = "lines",
          line = list(
            color = "black"
          ),
          hovertemplate = ~paste0(
            "Timestamp: ", timestamp, "<br>",
            "Price: ", scales::number(price), " ", str_to_upper(currencyParam), "<br>",
            "MA", MA1Param, ": ", scales::number(price_MA1), " ", str_to_upper(currencyParam), "<br>",
            "MA", MA2Param, ": ", scales::number(price_MA2), " ", str_to_upper(currencyParam),
            "<extra></extra>"
          )
        ) %>%
        add_trace(
          y = ~ price_MA1,
          name = paste0("MA",MA1Param),
          line = list(
            color = "#ffa500"
          )
        ) %>%
        add_trace(
          y = ~ price_MA2,
          name = paste0("MA",MA2Param),
          line = list(
            color = "#0000ff"
          )
        ) %>%
        layout(
          yaxis = list(
            title = str_to_upper(currencyParam)
          ),
          
          xaxis = list(
            title = "Timestamp"
          ),
          legend = list(orientation = "h",
                        xanchor = "center",
                        x = 0.5,
                        y = -0.2
          ),
          margin = list(
            t = 25
          )
        )
      
      volumeChart <- coinData %>%
        plot_ly(
          x = ~timestamp,
          y = ~total_volume,
          type = "bar",
          hovertemplate = ~paste0(
            "Timestamp: ", timestamp, "<br>",
            "24H Volume: ", scales::dollar(total_volume),
            "<extra></extra>"
          ),
          name = "24H Volume"
        ) %>%
        layout(
          yaxis = list(
            title = "24H Volume",
            showgrid = FALSE
          ),
          xaxis = list(
            title = "Timestamp"
          )
        )
      
      marketCapChart <- coinData %>%
        plot_ly(
          x = ~timestamp,
          y = ~market_cap,
          name = "Market Capitalization",
          type = "scatter",
          mode = "lines",
          line = list(
            color = "#cc8899"
          ),
          hovertemplate = ~paste0(
            "Timestamp: ", timestamp, "<br>",
            "Market Capitalization: ", scales::number(market_cap), " ", str_to_upper(currencyParam), 
            "<extra></extra>"
          )
        ) %>%
        layout(
          yaxis = list(
            title = str_to_upper(currencyParam),
            showgrid = FALSE
          ),
          xaxis = list(
            title = "Timestamp"
          ),
          legend = list(orientation = "h",
                        xanchor = "center",
                        x = 0.5,
                        y = -0.2
          )
        )
      
      subplot(priceChart, volumeChart, marketCapChart, shareX = TRUE, nrows = 3, 
              heights = c(0.5,0.25,0.25),
              margin = 0.05)
    })
    
    output$corrPlot <- renderPlotly({
      
      coinDataFOD <- coinData %>%
        mutate(timestamp = trunc(timestamp, timeGranularity)) %>%
        mutate(previousPrice = lag(price, 1, order_by=timestamp)) %>%
        mutate(priceDifferenceOrig = price - previousPrice) %>%
        filter(!is.na(priceDifferenceOrig))
      
      benchmarkDataFOD <- benchmarkData %>%
        mutate(timestamp = trunc(timestamp, timeGranularity)) %>%
        mutate(previousPrice = lag(price, 1, order_by=timestamp)) %>%
        mutate(priceDifferenceBenchmark = price - previousPrice) %>%
        filter(!is.na(priceDifferenceBenchmark))
      
      FOD <- coinDataFOD %>%
        inner_join(benchmarkDataFOD, by=c("timestamp")) %>%
        select(priceDifferenceOrig, priceDifferenceBenchmark) 
      
      lm_FOD <- linear_reg() %>%
        set_engine("lm") %>%
        set_mode("regression") %>%
        fit(priceDifferenceOrig ~ priceDifferenceBenchmark, data = FOD)
      
      xRange <- tibble(priceDifferenceBenchmark = seq(min(FOD$priceDifferenceBenchmark), 
                                                      max(FOD$priceDifferenceBenchmark),
                                                      length.out = 1000))
      
      yPred <- lm_FOD %>% predict(xRange) %>%
        bind_cols(xRange)
      
      R2 <- lm_FOD %>% 
        glance() %>%
        select(adj.r.squared) %>%
        pull()
      
      corrChart <- FOD %>%
        plot_ly(
          x = ~priceDifferenceBenchmark,
          y = ~priceDifferenceOrig,
          type = "scatter",
          mode = "markers",
          hoverinfo = "x+y"
        ) %>%
        add_trace(
          data = yPred,
          x=~priceDifferenceBenchmark,
          y=~.pred,
          type = "scatter",
          mode = "lines"
        ) %>%
        layout(
          annotations = list(text = glue("R2 = {scales::percent(R2)}"), 
                             xref='x domain', 
                             yref='y domain', 
                             x = 1, 
                             y = 0, 
                             showarrow=FALSE ),
          showlegend = FALSE,
          xaxis = list(
            title = glue("Bitcoin (BTC) FOD"),
            zeroline = FALSE
          ),
          yaxis = list(
            title = glue("{coinParam} FOD"),
            zeroline = FALSE
          ),
          margin = list(b = 80)
        )
    })
    
    output$table <- renderDataTable(server=FALSE, {
      coinData %>%
        datatable(extensions = 'Buttons',
                  options = list(pageLength = 8, dom = "Bfrtip",
                                 buttons = list(
                                   "copy",
                                   list(extend = "csv", filename = "coin_data"),
                                   list(extend = "excel", filename = "coin_data"),
                                   list(extend = "pdf", filename = "coin_data")
                                 ),
                                 ordering = FALSE,
                                 paging = TRUE),
                  colnames = c("Timestamp", "Price", "Market Cap", "24 H Volume"),
                  rownames = FALSE) %>%
        formatRound(.,
                    c("market_cap", "total_volume"),
                    digits = 2
                    )
    })
    
    
  })

}

