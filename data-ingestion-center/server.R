server <- function(input, output, session){
  
  rv <- reactiveValues(read_tbl = data.frame())
  
  observeEvent(req(input$read, input$upload_path), {
    
    ingested_file <- isolate(input$upload_path)
    header <- isolate(input$header)
    tbl <- read.csv(ingested_file$datapath, header = as.logical(header))
    rv$read_tbl <- tbl
    
    output$data_preview <- renderDT({
      datatable(tbl, 
                class = "table-bordered table-condensed",
                extensions = 'Buttons',
                options = list(pageLength = 10, dom = "Bfrtip",
                               buttons = list(
                                 "copy",
                                 list(extend = "csv", filename = "housing", title=NULL),
                                 list(extend = "excel", filename = "housing", title=NULL),
                                 list(extend = "pdf", filename = "housing", title=NULL)
                               )),
                rownames=FALSE)
    })
  })
  
  observeEvent(input$upload,{
    
    bucket <- isolate(input$bucket)
    bucketDir <- isolate(input$bucket_dir)
    
    s3write_using(rv$read_tbl, FUN = write.csv,
                  row.names=FALSE,
                  bucket = bucket,
                  object = paste0(bucketDir, ".csv"))
    
    output$outputMessage <- renderText({
      paste0("Upload to AWS S3 Successful on ", Sys.time())
    })
    
  })
  
}