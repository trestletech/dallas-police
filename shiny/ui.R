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
  leafletMap(
    "map", "100%", 400,
    initialTileLayer = "http://{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
    initialTileLayerAttribution = HTML('Maps by <a href="http://www.mapbox.com/">Mapbox</a> — Geocoding by <a href="http://mapquest.com">MapQuest</a>'),
    options=list(
      center = c(32.84, -96.7),
      zoom = 10,
      maxBounds = list(list(17, -180), list(59, 180))
    )
  ),
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