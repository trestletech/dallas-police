
# Use: Rscript backfill.R ../download/2014/ pointer.txt 500

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3){
  stop ("Must provide the dirname and number of API calls to consume.")
}
dir <- args[1]
pointer <- args[2]
count <- as.integer(args[3])

files <- list.files(dir, recursive=TRUE)

if (!file.exists(pointer)){
  ptr <- 1
} else {
  ptr <- as.integer(readLines(pointer))
}

# How many calls have been consumed today
counter <- 0

# Load utils
source("../scraper/geocode-utils.R")

# Load keys
source("../scraper/keys.R")

for (ptr in ptr:length(files)){
  cat("Processing file: ", files[ptr], " (",ptr,"/",length(files),")...\n")
  
  filePath <- file.path(dir, files[ptr])
  data <- read.csv(filePath)
  
  data$Zip <- as.character(data$Zip)
  data$Lat <- as.numeric(as.character(data$Lat))
  data$Long <- as.numeric(as.character(data$Long))
  
  nas <- which(is.na(data$Lat))
  
  if (length(nas) == 0){
    cat("\tNo missing entries.\n")
    next
  }
  
  addresses <- apply(data[nas,], 1, formatAddresses)
  
  for (i in 1:length(nas)){
    cat("\tGeocoding '", addresses[i], "'...\t")
    
    res <- geocode(addresses[i], cache="../scraper/cache.Rds", adv=TRUE, quiet=TRUE)
    val <- res$val
    counter <- counter + res$apiCalls
    
    data[nas[i], "Zip"] <- val$zip
    data[nas[i], "Lat"] <- val$lat
    data[nas[i], "Long"] <- val$long
        
    cat("Done.", ifelse(res$apiCalls == 0, "(cached)", ""), "\n")
    
    if (counter >= count){
      break
    }
  }
  
  write.csv(data, filePath, row.names=FALSE)
  
  if (counter >= count){
    cat("Interrupting. Reached ", counter, " API calls.\n")
    break
  }
}

# Update pointer to current file.
writeLines(as.character(ptr), pointer)



