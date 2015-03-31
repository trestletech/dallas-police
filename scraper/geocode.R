
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

source("geocode-utils.R")

data <- read.table(scrapedFile, sep="\t")
# Currently we have one extra column in front.
data <- data[,-1]
colnames(data) <- c("Incident", "Division", "Nature", "Priority", "DateTime", 
                    "UnitNum", "Block", "Street", "Beat", "ReportingArea", 
                    "Status", "UpdateTime")

data$Lat <- NA
data$Long <- NA
data$Zip <- NA

addresses <- apply(data, 1, formatAddresses)

if (length(unique(data$UpdateTime)) > 1){
  # Data spans more than one update. Could have duplicates or missed data.
  # Just omit.
  stop("Data spans multiple updates.")
}

try({  
  if (file.exists("keys.R")){
    source("keys.R")
  }

  # Copy the cache out so we can work with it transactionally
  cacheName <- paste0("cache-", runif(1, min=1000000, max=9999999), ".Rds")
  file.copy("cache.Rds", cacheName)

  geoOpen <- geocode(addresses, cache=cacheName)
  
  # Restore cache
  file.copy(cacheName, "cache.Rds")

  message(sum(!is.na(geoOpen$lat)), "/", length(addresses),
    " addresses filled via the open API.")
  
  data[, "Zip"] <- geoOpen$zip
  data[, "Lat"] <- geoOpen$lat
  data[, "Long"] <- geoOpen$long
})
write.csv(data, paste0("out-", as.integer(Sys.time()), ".csv"), row.names=FALSE)
