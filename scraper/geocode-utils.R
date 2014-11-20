
library(httr)
library(RJSONIO)
#' @param address A character or character vector of addresses to look up. Only
#' the unique addresses will be sent to the API.
#' @param api_id The app id for YDN
#' @param api_key The app secret for YDN
#' @param cache The path to the cache file
#' @param adv If TRUE will return a list with the response and a 'apiCalls' boolean telling you 
#'   where the response came from.
#' @return A data.frame with columns for the addresses (an in-order copy of the
#' vector provided as input complete with any redundant addresses), the zip
#' code, the latitude, and the longitude.
geocode <- function(address, api_id=getOption("RYDN_KEY"), 
                    api_key=getOption("RYDN_SECRET"), cache="cache.Rds", adv=FALSE, quiet=FALSE){
  toReturn <- data.frame(address = address)
  toReturn$zip <- NA
  toReturn$lat <- NA
  toReturn$long <- NA
  
  address <- unique(address)
  
  apiCalls <- 0
  
  library(rydn)
  for (i in 1:length(address)){
    
    res <- checkCache(address[i], cache)
    
    if (is.null(res)){
      # Do geolocation
      apiCalls <- apiCalls + 1
      if (!quiet){
        cat("Doing geolocation for '", address[i], "'\n")
      }
      res <- find_place(address[i]) 
    }
    
    rowInd <- toReturn$address == address[i]
    
    # until stringsAsFactores=FALSE is in rydn...
    res$quality <- as.integer(as.character(res$quality))
    res$postal <- as.character(res$postal)
    res$latitude <- as.numeric(as.character(res$latitude))
    res$longitude <- as.numeric(as.character(res$longitude))
    
    if (apiCalls > 0){
      addToCache(address[i], res, cache)
    }
    
    if (nrow(res) > 0 && max(res$quality) >= 70){
      maxRes <- which(res$quality == max(res$quality))
      # Pick the first if there's a tie.
      maxRes <- maxRes[1]
      
      toReturn[rowInd,"zip"] <- res[maxRes, "postal"]
      toReturn[rowInd,"lat"] <- res[maxRes, "latitude"]
      toReturn[rowInd,"long"] <- res[maxRes, "longitude"]
    }
  }
  
  if (adv){
    return(list(val=toReturn, apiCalls=apiCalls))
  }
  
  toReturn
}

#' Can optionally pass in cache if it's already loaded into memory
checkCache <- function(address, rdsFile, cache=NULL){
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
addToCache <- function(raw, result, rdsFile, cache=NULL){
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

formatAddresses <- function(thisRow){
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
}
