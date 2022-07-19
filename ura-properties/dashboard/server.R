server <- function(input, output, session){
  
  observeEvent(input$select, {
    
    year_selected <- isolate(input$year)
    month_selected <- isolate(input$month)
    month_modified <- as.character(as.Date(paste0(year_selected,"-",month_selected,"-01"),
                              "%Y-%b-%d"))
    property_type_selected <- isolate(input$propType)
    
    
    ### Filtering Transactions ----
    
    transactions <- tbl(conn, "URA_PRIVATE") %>%
      filter(PROPERTY_TYPE %in% property_type_selected) %>%
      mutate(psf = PRICE/AREA) %>%
      filter(MONTH==month_modified) %>%
      select(LONGITUDE, LATITUDE, PROJECT, DISTRICT, STREET, psf, PROPERTY_TYPE, MONTH) %>%
      filter(!is.na(LONGITUDE)) %>%
      collect(.)
    
    ### Converting Polygons to SFC object ----
    
    polygons_sfc <- polygons %>%
      rowwise() %>%
      mutate(geometry = st_as_sfc(GEOJSON, GeoJSON=TRUE)) %>%
      ungroup() %>%
      select(PLN_AREA_N, geometry)
    
    ### Calculating Intersections between Points and Polygons ----
    
    locations <- transactions %>%
      select(LONGITUDE, LATITUDE) %>%
      rename(x=LATITUDE, y=LONGITUDE) 
    locations_sf <- sf::st_as_sf(locations, coords=c("y","x"), crs=4326)
    valid_poly <- st_make_valid(polygons_sfc$geometry) 
    intersection <- st_intersects(locations_sf$geometry, valid_poly)
    
    ### Combine Polygons + Points ----
    
    ### Transactions POV
    
    transactions_w_polygon <- tibble(polygon_id = unlist(intersection)) %>%
      bind_cols(transactions) %>%
      inner_join(polygons %>%
                   rowid_to_column(
                     "polygon_id"
                   ), 
                 "polygon_id")
    
    ### Polygon POV
    
    polygons_sfc_modified <- polygons_sfc %>%
      inner_join(
        transactions_w_polygon %>%
          group_by(PLN_AREA_N) %>%
          summarise(
            median_price = median(psf)
          ), "PLN_AREA_N"
      ) %>%
      ungroup() %>%
      arrange(desc(median_price)) %>%
      mutate(label = str_c(PLN_AREA_N, " (", scales::dollar(median_price), ")"))
    
    
    output$chart1 <- renderLeaflet({
      transactions %>%
        filter(MONTH==month_modified) %>%
        filter(!is.na(LONGITUDE)) %>%
        group_by(LONGITUDE, LATITUDE, PROJECT, DISTRICT, STREET) %>%
        count() %>%
        leaflet() %>%
        setView(lng = 103.819836, lat = 1.352083, zoom = 12) %>% 
        addTiles() %>%
        addCircleMarkers(
          ~LONGITUDE, ~LATITUDE, popup=~paste0(
            "Project: ", PROJECT, "<br/>",
            "District: ", DISTRICT, "<br/>",
            "Address: ", STREET, "<br/>",
            "Transactions: ", n
          ),
          fillOpacity = 0.1,
          color = "navy",
          radius = 1,
        )
    })
    
    ### Colour Palette ----
    
    pal <- colorBin(c("green", "red"), polygons_sfc_modified$median_price,
                    bins = seq(8000,32000, 8000))
    
    output$chart2 <- renderLeaflet({
      transactions %>%
        filter(!is.na(LONGITUDE)) %>%
        group_by(LONGITUDE, LATITUDE, PROJECT, DISTRICT, STREET) %>%
        count() %>%
        leaflet() %>%
        setView(lng = 103.819836, lat = 1.352083, zoom = 12) %>% 
        addTiles() %>%
        addMarkers(
          ~LONGITUDE, ~LATITUDE, popup=~paste0(
            "Project: ", PROJECT, "<br/>",
            "District: ", DISTRICT, "<br/>",
            "Address: ", STREET, "<br/>",
            "Transactions: ", n
          ),
          clusterOptions = markerClusterOptions()
        )
    })
    
    output$chart3 <- renderPlotly({
      transactions_w_polygon %>%
        group_by(PLN_AREA_N) %>%
        count() %>%
        arrange(desc(n)) %>%
        plot_ly(.,
                labels = ~ paste0(PLN_AREA_N,"<br>",
                                  scales::comma(n)),
                parents = NA,
                values = ~n,
                type = "treemap",
                hovertemplate = ~paste0(
                  PLN_AREA_N, "<br>",
                  "Transactions: ", scales::comma(n),
                  "<extra></extra>"
                ))
    })
    
    output$chart4 <- renderLeaflet({
      leaflet(polygons_sfc_modified) %>%
        addTiles() %>%
        setView(lng = 103.819836, lat = 1.352083, zoom = 12) %>% 
        addPolygons(
          data = polygons_sfc_modified$geometry,
          label = polygons_sfc_modified$label,
          fillColor = pal(polygons_sfc_modified$median_price), 
          weight = 2
        ) %>%
        addCircleMarkers(
          transactions$LONGITUDE, 
          transactions$LATITUDE, 
          fillOpacity = 0.1,
          color = "navy",
          radius = 1,
          popup=~paste0(
            "Project: ", transactions$PROJECT, "<br/>",
            "District: ", transactions$DISTRICT, "<br/>",
            "Address: ", transactions$STREET, "<br/>"
          )
        ) %>% 
        addLegend(pal = pal, values = polygons_sfc_modified$median_price, 
                  opacity = 0.7, 
                  title = "PSF (S$)",
                  position = "bottomright")
    })
    
    output$chart5 <- renderLeaflet({
      leaflet(polygons_sfc_modified) %>%
        addTiles() %>%
        setView(lng = 103.819836, lat = 1.352083, zoom = 12) %>% 
        addPolygons(
          data = polygons_sfc_modified$geometry,
          label = polygons_sfc_modified$label,
          fillColor = pal(polygons_sfc_modified$median_price), 
          weight = 2
        ) %>% 
        addLegend(pal = pal, values = polygons_sfc_modified$median_price, 
                  opacity = 0.7, 
                  title = "PSF (S$)",
                  position = "bottomright")
      
    })
    
    
  })
  

  
}