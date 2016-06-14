library(shiny)
library(leaflet)
library(ggplot2)
library(httr)
library(plyr)
library(dplyr)
library(dallasgeolocate)

data <- reactiveValues(calls=data.frame())

observe({
  invalidateLater(60000, NULL)
  
  raw <- GET(url="https://www.dallasopendata.com/resource/are8-xahz.json")
  vals <- content(raw)
  dat <- ldply(vals, data.frame)
  
  adds <- dallasgeolocate::render_locations(as.character(dat$block), as.character(dat$location))
  locs <- dallasgeolocate::find_location(adds)
  locDF <- ldply(lapply(locs, as.list), data.frame)
  
  locDat <- cbind(dat, locDF)
  colnames(locDat)[(ncol(locDat)-2):(ncol(locDat)-1)] <- c("long", "lat")
  
  tbl <- as_data_frame(locDat)
  tbl <- tbl %>% 
    mutate(uniqueLoc = paste(long, lat)) %>% 
    group_by(uniqueLoc) %>% 
    summarize(
      date_time = min(as.character(date_time)), 
      incident_number = incident_number[1],
      priority = max(as.character(priority)),
      nature_of_call = nature_of_call[1],
      block=block[1], 
      location = location[1],
      long = long[1], 
      lat=lat[1]) %>% 
    ungroup() %>% 
    select(-uniqueLoc)
  
  data$calls <- tbl
})

pal <- colorFactor(c("#FF0000", "#CCCC11", "#009900", "#009900"), domain = 1:4)

shinyServer(function(input, output, session) {
  output$desc <- reactive({
    print("Desc")
    req(data$calls)
    
    list(
      activeNum = nrow(data$calls),
      lastUpdate = max(Sys.time())
    )
  })
  
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      addCircleMarkers(~long, ~lat, data = filter(data$calls, !is.na(lat)),
                       color = ~pal(as.integer(priority)),
                       stroke = FALSE,
                       fillOpacity=.7,
                       popup = ~paste0("<strong>", incident_number, "</strong><br/>",
                                       "Priority: ", priority, "<br />",
                                       nature_of_call))
  })
    
  output$callTable <- renderDataTable({
    data$calls %>% 
      select(-lat, -long) %>% 
      arrange(priority)
  })
  
})