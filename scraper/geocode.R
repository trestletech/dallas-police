
#' Expect args in the format of:
#' Rscript geocode.R <outputFile> <MAPQUEST_KEY>

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
#' @param address A character or character vector of addresses to look up. Only
#' the unique addresses will be sent to the API.
#' @param key The key for the Mapquest API (NOT URL encoded).
#' @param open If TRUE will use Mapquest's open (OpenStreetMaps) API, if FALSE,
#' will use their commercial API (which has a more stringent quota, so we only
#' want to use it sparingly).
#' @return A data.frame with columns for the addresses (an in-order copy of the
#' vector provided as input complete with any redundant addresses), the zip
#' code, the latitude, and the longitude.
geocode <- function(address, key=getOption("MAPQUEST_KEY"), open=TRUE){
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
  
  prefix <- ifelse(open, "open", "www")
  
  url <- paste0("http://",prefix,".mapquestapi.com/geocoding/v1/batch?&key=",
                key, "&json=", URLencode(json))
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
  
  address <- sub(" / ", " and ", address)
  
  address
})

if (length(unique(data$UpdateTime)) > 1){
  # Data spans more than one update. Could have duplicates or missed data.
  # Just omit.
  stop("Data spans multiple updates.")
}

# Provide whatever addresses we can from the cache
try({
  if (!file.exists("addressCache.Rds")){
    return()
  }
  addressCache <- readRDS("addressCache.Rds")
  
  matchInd <- match(addresses, addressCache$addresses)
  
  message(sum(!is.na(matchInd)), "/", nrow(data),
          " addresses filled from the cache.")
  
  data$Zip <- addressCache[matchInd, "Zip"]
  data$Lat <- addressCache[matchInd, "Lat"]
  data$Long <- addressCache[matchInd, "Long"]
}, silent=TRUE)

# Get whatever data we can from the open API
try({
  naRows <- is.na(data$Lat)
  geoOpen <- geocode(addresses[naRows], open=TRUE)
  
  message(sum(!is.na(geoOpen$lat)), "/", sum(naRows),
    " addresses filled via the open API.")
  
  data[naRows, "Zip"] <- geoOpen$zip
  data[naRows, "Lat"] <- geoOpen$lat
  data[naRows, "Long"] <- geoOpen$long
}, silent=TRUE)

# Try to get any missing data from the commercial API
try({
  naRows <- is.na(data$Lat)
  geoComm <- geocode(addresses[naRows], open=FALSE)
  
  message(sum(!is.na(geoComm$lat)), "/", sum(naRows),
    " addresses filled via the commercial API.")
  
  data[naRows,"Zip"] <- geoComm$zip
  data[naRows,"Lat"] <- geoComm$lat
  data[naRows,"Long"] <- geoComm$long
}, silent=TRUE)

# Cache the addresses on disk so that we don't have to look up the addresses
# that we already looked up in the previous minute.
addressCache <- data[,c("Block", "Street", "Lat", "Long", "Zip")]
addressCache <- cbind(addresses, addressCache)
addressCache <- unique(addressCache)

saveRDS(addressCache, file="addressCache.Rds")

write.csv(data, paste0("out-", as.integer(Sys.time()), ".csv"), row.names=FALSE)
