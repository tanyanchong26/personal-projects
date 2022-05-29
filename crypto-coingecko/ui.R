ui <- navbarPage("Crypto Dashboard",
                 id = "coin_gecko",
                 theme = shinytheme("superhero"),
                 header = tagList(
                   useShinydashboard(),
                   tags$head(
                     tags$style(
                       HTML(
                         "
                         #table {
                         background: #ffffff;
                         }
                         .dt-buttons {
                         margin-top: 20px;
                         margin-left: 20px;
                         }
                         .dataTables_filter {
                         margin-right: 20px;
                         margin-top: 20px;
                         }
                         .display.dataTable.no-footer {
                         margin-left: 20px;
                         margin-right: 20px;
                         width: 95%;
                         }
                         .dataTables_info {
                         margin-left: 20px;
                         margin-bottom: 20px;
                         }
                         .dataTables_paginate.paging_simple_numbers {
                         margin-right: 40px;
                         margin-bottom: 20px;
                         }
                         #run {
                         border-color: #ffffff;
                         }
                         #remarks {
                         font-size: 10px;
                         }
                         "
                       )
                     )
                   )
                 ),
                 tabPanel(
                   "CoinGecko",
                   sidebarLayout(
                     sidebarPanel(
                       width = 2,
                       fluidRow(
                         selectInput(
                           "coin",
                           "Coin",
                           coinDetailsNameList
                         ),
                         selectInput(
                           "currency",
                           "Currency",
                           str_to_upper(supportedCurrencies)
                         ),
                         numericInput(
                           "period",
                           "Period (Days)",
                           value = 30, 
                           min = 1,
                           max = 365
                         ),
                         numericInput(
                           "ma1",
                           "MA1 Period",
                           value = 7,
                           min = 3,
                           max = 90
                         ),
                         numericInput(
                           "ma2",
                           "MA2 Period",
                           value = 30,
                           min = 3,
                           max = 90
                         ),
                         actionButton(
                           "run",
                           "Run"
                         ),
                         h2(""),
                         verbatimTextOutput("remarks")
                       )
                     ),
                     mainPanel(
                       width = 10,
                       column(12,
                              fluidRow(
                                plotlyOutput("priceChart", height = "850px"),
                                plotlyOutput("corrPlot", height = "300px"),
                                h2(""),
                                DTOutput("table")
                              )
                       )
                     )
                   )
                 )
)