# One of these needs to be loaded or you get a weird error about the methods package...
library(dallasgeolocate)
library(rgeos)
library(sp)
library(rgdal)

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

data <- read.table(scrapedFile, sep="\t", stringsAsFactors=FALSE)
# Currently we have one extra column in front.
data <- data[,-1]
colnames(data) <- c("Incident", "Division", "Nature", "Priority", "DateTime", 
                    "UnitNum", "Block", "Street", "Beat", "ReportingArea", 
                    "Status", "UpdateTime")

data$Lat <- NA
data$Long <- NA

library(dallasgeolocate)


if (length(unique(data$UpdateTime)) > 1){
  # Data spans more than one update. Could have duplicates or missed data.
  # Just omit.
  stop("Data spans multiple updates.")
}

try({  
  locs <- dallasgeolocate::render_locations(data$Block, data$Street)
  add <- dallasgeolocate::find_location(locs)
  
  data[, "Lat"] <- sapply(add, "[[", "y")
  data[, "Long"] <- sapply(add, "[[", "x")
  
})
write.csv(data, paste0("out-", as.integer(Sys.time()), ".csv"), row.names=FALSE)
