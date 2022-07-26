ui <- navbarPage("Property Prices in Singapore",
                 id = "condo",
                 theme = shinytheme("flatly"),
                 header = tagList(
                   useShinydashboard(),
                   tags$head(
                     tags$style(
                       HTML(
                         "
                         .well {
                         padding-top: 20px;
                         padding-left: 30px;
                         padding-right: 30px;
                         padding-bottom: 20px;
                         }
                         .box-title {
                         font-weight: bold;
                         font-size: 28px;
                         color: #ffffff;
                         }
                         .box-header {
                         background-color: #2c3e50
                         }
                         "
                       )
                     )
                   )
                   ),
                 tabPanel(
                   "Price by Region",
                   sidebarLayout(
                     sidebarPanel(
                       width = 2,
                       fluidRow(
                         sliderInput(
                           "year",
                           "Year",
                           min = start_year,
                           max = end_year,
                           value = end_year,
                           step = 1,
                           sep = "",
                           ticks = FALSE
                         ),
                         selectInput(
                           "month",
                           "Month",
                           month_list,
                           selected = month.abb[month(Sys.Date() - months(1))],
                           multiple = FALSE
                         ),
                         selectInput(
                           "propType",
                           "Property Type",
                           prop_type,
                           multiple = TRUE
                         ),
                         actionButton(
                           "select",
                           "Select"
                         )
                       )
                     ),
                     mainPanel(
                       width = 10,
                       column(12,
                              fluidRow(
                                box(
                                  leafletOutput("chart1", height = 600),
                                  title = "Iteration 1",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  collapsed = TRUE,
                                  width = 12
                                ),
                                box(
                                  leafletOutput("chart2", height = 600),
                                  title = "Iteration 2",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  collapsed = TRUE,
                                  width = 12
                                ),
                                box(
                                  plotlyOutput("chart3", height = "400px"),
                                  title = "Iteration 3",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  collapsed = TRUE,
                                  width = 12
                                ),
                                box(
                                  leafletOutput("chart4", height = 600),
                                  title = "Iteration 4",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  collapsed = TRUE,
                                  width = 12
                                ),
                                box(
                                  leafletOutput("chart5", height = 600),
                                  title = "Iteration 5",
                                  solidHeader = TRUE,
                                  collapsible = TRUE,
                                  collapsed = TRUE,
                                  width = 12
                                )
                              )
                       )
                     )
                   )
                 )
)