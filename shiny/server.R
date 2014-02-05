library(leaflet)
library(ggplot2)
library(maps)
library(httr)

# From a future version of Shiny
bindEvent <- function(eventExpr, callback, env=parent.frame(), quoted=FALSE) {
  eventFunc <- exprToFunction(eventExpr, env, quoted)
  
  initialized <- FALSE
  invisible(observe({
    eventVal <- eventFunc()
    if (!initialized)
      initialized <<- TRUE
    else
      isolate(callback())
  }))
}

data <- reactiveValues(calls=data.frame(), selectedIncident=NULL)

observe({
  invalidateLater(60000, NULL)
  
  print("Downloading new data")
  
  allCalls <- content(GET("http://s3.amazonaws.com/dallas-police/current.csv"))
  
  data$calls <- allCalls[!duplicated(allCalls[,"Incident"]),]
  data$allCalls <- allCalls
})

shinyServer(function(input, output, session) {
  output$desc <- reactive({
    if (is.null(data$allCalls))
      return(list())
    list(
      activeNum = nrow(data$calls),
      lastUpdate = max(data$calls$UpdateTime)
    )
  })
  
  
  # Create the map; this is not the "real" map, but rather a proxy
  # object that lets us control the leaflet map on the page.
  map <- createLeafletMap(session, 'map')
  
  observe({
    map$clearMarkers()
    
    input$map_zoom
    
    if (nrow(data$calls) == 0)
      return()
    
    calls <- data$calls
    
    for (i in 1:nrow(calls)){
      thisRow <- calls[i,]  
      
      map$addMarker(
        thisRow$Lat,
        thisRow$Long,
        #100000000 / input$map_zoom^5,
        thisRow$Incident,
        list(
          weight=1.2,
          fill=TRUE,
          color='#4A9'
        )
      )
    }
    
    
  })
  
  bindEvent(input$map_click, function() {
    data$selectedIncident <- NULL
  })
  
  bindEvent(input$map_marker_click, function() {
    event <- input$map_marker_click
    map$clearPopups()
    
    incident <- data$calls[data$calls$Incident == event$id,]
    data$selectedIncident <- incident
    
    allUnits <- data$allCalls[data$allCalls$Incident == event$id,]
    
    content <- as.character(tagList(
      tags$strong(ifelse(is.na(incident$Block), 
                         incident$Street, 
                         paste(incident$Block, incident$Street))),
      tags$br(),
      incident$Nature,
      tags$br(),
      paste0("Incident #", incident$Incident),
      tags$br(),
      paste0("Unit",ifelse(nrow(allUnits) > 1, "s", ""),
             ": ", paste(allUnits$UnitNum, collapse=", ")),
      tags$br(),
      div(incident$DateTime, class="grey")
      
      
    ))
    map$showPopup(event$lat, event$lng, content, event$id)
  })
  
})