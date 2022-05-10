ui <- navbarPage("Shiny I/O Demo",
                 id = "io_demo",
                 theme = shinytheme("flatly"),
                 header = tagList(
                   useShinydashboard(),
                   tags$head(
                     tags$style(
                       HTML(
                         "
                       .box-header {
                       color:#ffffff;
                       background:#222d32;
                       text-align:center;
                       }
                       .box-header h3.box-title{
                       font-weight: bold;
                       font-size: 24px;
                       text-padding: 20px;
                       }
                       .form-group {
                       margin-left: 20px;
                       margin-right: 20px;
                       }
                       h5 {
                       margin-left: 20px;
                       }
                       #textOutputResult {
                       margin-left: 20px;
                       margin-bottom: 20px;
                       }
                       .form-control {
                       height: 35px;
                       }
                       .btn {
                       margin-left: 20px;
                       }
                       #tab-5353-1 > div > div:nth-child(1) > div > div > div.box-body > div > div:nth-child(4) {
                       margin-top: 15px;
                       }
                       #textAreaOutputResult {
                       margin-left: 20px;
                       }
                       #generateHistogram {
                       margin-bottom: 20px;
                       }
                       #histogram > img {
                       margin-left: 20px;
                       }
                       #map {
                       margin-left: 200px;
                       }
                       #searchOutcome {
                       margin-left: 20px;
                       margin-right: 20px;
                       }
                       #searchTable {
                       margin-left: 20px;
                       margin-right: 20px;
                       }
                       #header {
                       height: 35px inherit;
                       }
                       .btn {
                       padding: 5px 15px;
                       }
                       .progress {
                       margin-top: 5px;
                       height: 18px;
                       }
                       "
                       )
                     )
                   )
                 ), 
                 tabPanel("Inputs",
                          fluidRow(
                            column(4,
                                   box(
                                     fluidRow(
                                       textInput("name", "Enter your name!"),
                                       h5("Mirror mirror on the wall ..."),
                                       htmlOutput("textOutputResult"),
                                       textAreaInput("life_story", "Tell me your live story"),
                                       htmlOutput("textAreaOutputResult")
                                     ),
                                     title = "Text Input/Text Area Input",
                                     solidHeader = TRUE,
                                     collapsible = TRUE,
                                     collapsed = TRUE,
                                     width = 12
                                   )
                            ),
                            column(4,
                                   box(
                                     fluidRow(
                                       radioButtons("category", "Select a category", c("Forex", "Equity"), inline=TRUE),
                                       conditionalPanel(
                                         condition = "input.category == 'Forex'",
                                         splitLayout(
                                             textInput("from_forex", "From"),
                                             textInput("to_forex", "To")
                                           )
                                         ),
                                       conditionalPanel(
                                         condition = "input.category == 'Equity'",
                                         textInput("ticker", "Ticker", width = "50%")
                                       ),
                                       dateRangeInput("tickerDateRange", "Select a Date Range"),
                                       actionButton("generateButton", "Generate"),
                                       plotlyOutput(
                                         "chartOutputResult"
                                       )
                                       ),
                                       title = "Radio Button/Split Layout/Date Range Input/Action Button/Conditional Panel/Plotly",
                                       solidHeader = TRUE,
                                       collapsible = TRUE,
                                       collapsed = TRUE,
                                       width = 12
                                     )
                                   ),
                            column(4,
                                   box(
                                     fluidRow(
                                       numericInput("obs", "Observations", value = 100, min = 50, max=1000),
                                       numericInput("mean", "Mean", value = 100, min = 50, max=1000),
                                       numericInput("standev", "Standard Deviation", value = 50, min = 50, max=1000),
                                       sliderInput("rng", "Range", value = c(50, 250), min=0, max=2000),
                                       actionButton("generateHistogram", "Generate"),
                                       plotOutput("histogram", width = "95%")
                                     ),
                                     title = "Numeric Input/Numeric Range Input/ggplot2",
                                     solidHeader = TRUE,
                                     collapsible = TRUE,
                                     collapsed = TRUE,
                                     width = 12
                                   )
                                   ),
                            column(12,
                                   box(
                                     fluidRow(
                                       textInput("search", "Search Location"),
                                       actionButton("triggerSearch", "Search"),
                                       h5(""),
                                       leafletOutput("map", width="75%", height = 600),
                                       h5(""),
                                       verbatimTextOutput("searchOutcome"),
                                       DTOutput("searchTable", width = "95%")
                                     ),
                                     title = "Map Output/Verbatim Text Output/Data Table Output",
                                     solidHeader = TRUE,
                                     collapsible = TRUE,
                                     collapsed = TRUE,
                                     width = 12
                                   )
                                   ),
                            column(12,
                                   box(
                                     fluidRow(
                                       column(
                                         3,
                                         fileInput(
                                           "upload_path",
                                           "Path"
                                         ),
                                         radioButtons(
                                           "header", 
                                           "Headers", 
                                           c("TRUE", "FALSE"), 
                                           inline=TRUE),
                                         actionButton(
                                           "read",
                                           "Read"
                                         )
                                       ),
                                       column(
                                         9,
                                         DTOutput("data_preview", width = "95%")
                                       )
                                     ),
                                     title = "File Input/Table Output",
                                     solidHeader = TRUE,
                                     collapsible = TRUE,
                                     collapsed = TRUE,
                                     width = 12
                                   )
                                   )
                          )
                          )
)
