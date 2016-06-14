library(leaflet)
library(ShinyDash)

row <- function(...) {
  tags$div(class="row", ...)
}

col <- function(width, ...) {
  tags$div(class=paste0("span", width), ...)
}

actionLink <- function(inputId, ...) {
  tags$a(href='javascript:void',
         id=inputId,
         class='action-button',
         ...)
}

shinyUI(bootstrapPage(
  tags$head(tags$link(rel='stylesheet', type='text/css', href='styles.css')),
  leafletOutput("map", "100%", 400),
  
  tags$div(
    class = "container",
    
    tags$p(tags$br()),
    row(
      col(3, tags$br()),
      col(8, h2('Real-time Dallas Police Calls'))
    ),
    row(
      col(
        12,
        htmlWidgetOutput(
          outputId = 'desc',
          HTML(paste(
            'Showing the <span id="activeNum"></span> calls the Dallas Police are responding to as of <span id="lastUpdate"></span><br/>'
          ))
        )
      )
    ),
    tags$hr(),
    row(
      col(
        12,
        dataTableOutput("callTable")
        
      )
    )
  )
))