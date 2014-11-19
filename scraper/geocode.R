
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
#' @param api_id The app id for YDN
#' @param api_key The app secret for YDN
#' @return A data.frame with columns for the addresses (an in-order copy of the
#' vector provided as input complete with any redundant addresses), the zip
#' code, the latitude, and the longitude.
geocode <- function(address, api_id=getOption("RYDN_KEY"), 
                    api_key=getOption("RYDN_SECRET")){
  toReturn <- data.frame(address = address)
  toReturn$zip <- NA
  toReturn$lat <- NA
  toReturn$long <- NA
  
  address <- unique(address)
  
  library(rydn)
  for (i in 1:length(address)){
    
    res <- checkCache(address[i])
    
    if (is.null(res)){
      # Do geolocation
      cat("Doing geolocation for '", address[i], "'\n")
      res <- find_place(address[i]) 
    }
    
    rowInd <- toReturn$address == address[i]
    
    # until stringsAsFactores=FALSE is in rydn...
    res$quality <- as.integer(as.character(res$quality))
    res$postal <- as.character(res$postal)
    res$latitude <- as.numeric(as.character(res$latitude))
    res$longitude <- as.numeric(as.character(res$longitude))
    
    addToCache(address[i], res)
    
    if (nrow(res) > 0 && max(res$quality) >= 70){
      maxRes <- which(res$quality == max(res$quality))
      # Pick the first if there's a tie.
      maxRes <- maxRes[1]
      
      toReturn[rowInd,"zip"] <- res[maxRes, "postal"]
      toReturn[rowInd,"lat"] <- res[maxRes, "latitude"]
      toReturn[rowInd,"long"] <- res[maxRes, "longitude"]
    }
  }
  
  toReturn
}

#' Can optionally pass in cache if it's already loaded into memory
checkCache <- function(address, rdsFile="cache.Rds", cache=NULL){
  if (is.null(cache)){
    if (!file.exists(rdsFile)){
      return(NULL)
    }
    cache <- readRDS(rdsFile)
  }
  
  if (!exists(address, envir=cache, inherits = FALSE)){
    return(NULL)
  }
  return(get(address, envir=cache, inherits=FALSE))
}

#' Can optionally pass in cache if it's already loaded into memory
addToCache <- function(raw, result, rdsFile="cache.Rds", cache=NULL){
  if (is.null(cache)){
    if (file.exists(rdsFile)){
      cache <- readRDS(rdsFile)
    } else{
      cache <- new.env()
    }
  }
  
  if (exists(raw, envir=cache, inherits=FALSE)){
    warning("Already had address in cache")
  }
  assign(raw, result, envir=cache)
  
  saveRDS(cache, rdsFile)
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
  
  # Deal with "Marvin D Love Fwy Nb / L B J Fwy Eb"
  address <- gsub("\\bNb\\b", "", address)
  address <- gsub("\\bWb\\b", "", address)
  address <- gsub("\\bEb\\b", "", address)
  address <- gsub("\\bSb\\b", "", address)
  
  address <- paste0(address, ", Dallas, TX, USA")
  
  address
})

if (length(unique(data$UpdateTime)) > 1){
  # Data spans more than one update. Could have duplicates or missed data.
  # Just omit.
  stop("Data spans multiple updates.")
}

try({  
  if (file.exists("keys.R")){
    source("keys.R")
  }
  geoOpen <- geocode(addresses)
  
  message(sum(!is.na(geoOpen$lat)), "/", length(addresses),
    " addresses filled via the open API.")
  
  data[, "Zip"] <- geoOpen$zip
  data[, "Lat"] <- geoOpen$lat
  data[, "Long"] <- geoOpen$long
})
print("then")
write.csv(data, paste0("out-", as.integer(Sys.time()), ".csv"), row.names=FALSE)
