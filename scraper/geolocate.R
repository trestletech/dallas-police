
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
#' @param key The key for the Mapquest API (NOT URL encoded).
geolocate <- function(address, key=getOption("MAPQUEST_KEY")){
  url <- paste0("http://www.mapquestapi.com/geocoding/v1/address?&key=",
                URLencode(key), "&street=", URLencode(address),
                "&city=Dallas&state=TX")
  info <- content(GET(url))
  
  if (length(info$results[[1]]$locations) < 1){
    stop(paste0("Error looking up address: ", address))
  }
  
  info$results[[1]]$locations[[1]]
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

for (i in 1:nrow(data)){
  thisRow <- data[i,]
  address <- NULL
  if (is.na(thisRow$Block)){
    address <- thisRow$Street
  } else{
    address <- paste(thisRow$Block, thisRow$Street)
  }
  
  try({
    geo <- geolocate(address)
    data[i, "Zip"] <- geo$postalCode
    data[i, "Lat"] <- geo$latLng$lat
    data[i, "Long"] <- geo$latLng$lng
  }, TRUE)
}

write.csv(data, "out.csv")
