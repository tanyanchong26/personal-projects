ui <- navbarPage("SEA Shiny Demo",
                 id = "demo",
                 tabPanel(
                   "Data Ingestion Centre",
                   sidebarLayout(
                     sidebarPanel(
                       width = 2,
                       fluidRow(
                         fileInput(
                           "upload_path",
                           "Upload"
                         ),
                         selectInput(
                           "header",
                           "Headers",
                           choices = c("TRUE", "FALSE"),
                           selected = "TRUE",
                           multiple = FALSE
                         ),
                         textInput(
                           "bucket",
                           "Name of Bucket"
                         ),
                         textInput(
                           "bucket_dir",
                           "Bucket Directory"
                         ),
                         actionButton(
                           "read",
                           "Read File"
                         ),
                         actionButton(
                           "upload",
                           "Upload to S3"
                         ),
                         h2(
                           ""
                         ),
                         verbatimTextOutput(
                           "outputMessage",
                           placeholder = TRUE
                         )
                       )
                     ),
                     mainPanel(
                       width = 10,
                       column(12,
                              DTOutput("data_preview", width = "100%", height = "auto"),
                              style = "overflow-x: scroll;"
                       )
                     )
                   )
                 )
)