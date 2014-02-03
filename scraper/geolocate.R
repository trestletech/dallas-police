
#' Expect args in the format of:
#' Rscript geolocate.R <outputFile> <MAPQUEST_KEY>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2){
  options(`MAPQUEST_KEY` = args[2])
}
if (length(args) < 1){
  stop ("Must provide the filename as the first argument to the script.")
}
scrapedFile <- args[1]

library(httr)
library(RJSONIO)
#' @param key The key for the Mapquest API (NOT URL encoded).
geolocate <- function(address, key=getOption("MAPQUEST_KEY")){
  toReturn <- data.frame(address = address)
  toReturn$zip <- NA
  toReturn$lat <- NA
  toReturn$long <- NA
  
  if (is.null(key) || key == ""){
    stop("You must provide a mapquest key.")
  }
  
  address <- unique(address)
  
  # These JSON libraries are proving useless, so we'll just serialize it ourselves.
  json <- paste0('{locations:[',
                 paste0(paste0('{street:"', address, '",city:"Dallas",state:"TX"}'),
                 collapse=",")
                 ,']}')
  
  url <- paste0("http://open.mapquestapi.com/geocoding/v1/batch?&key=",
                URLencode(key), "&json=", URLencode(json))
  #print(paste("Getting: ", url ))
  info <- content(GET(url))
  
  for (i in 1:length(info$results)){
    res <- info$results[[i]]
    rowInd <- which(res$providedLocation$street == toReturn$address)
    
    if (length(res$locations) >= 1){
      toReturn[rowInd,"zip"] <- res$locations[[1]]$postalCode
      toReturn[rowInd,"lat"] <- res$locations[[1]]$latLng$lat
      toReturn[rowInd,"long"] <- res$locations[[1]]$latLng$lng 
    }
  }
  
  toReturn
}


data <- read.table(scrapedFile, sep="\t")
# Currently we have one extra column in front.
data <- data[,-1]
colnames(data) <- c("Incident", "Division", "Nature", "Priority", "DateTime", 
                    "UnitNum", "Block", "Street", "Beat", "ReportingArea", 
                    "Status", "UpdateTime")

data$Lat <- NA
data$Long <- NA
data$Zip <- NA

addresses <- apply(data, 1, function(thisRow){
  address <- NULL
  if (is.na(thisRow["Block"])){
    address <- thisRow["Street"]
  } else{
    address <- paste(thisRow["Block"], thisRow["Street"])
  }
  
  address
})

if (length(unique(data$UpdateTime)) > 1){
  # Data spans more than one update. Could have duplicates or missed data.
  # Just omit.
  stop("Data spans multiple updates.")
}

try({
  geo <- geolocate(addresses)
  data$Zip <- geo$zip
  data$Lat <- geo$lat
  data$Long <- geo$long
}, silent=TRUE)

write.csv(data, paste0("out-", as.integer(Sys.time()), ".csv"), row.names=FALSE)
