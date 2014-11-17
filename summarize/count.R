
# paste0(allCalls$Block, "|||", allCalls$Steet, "|||", allCalls$Zip)

joinTables <- function(tab1, tab2) {
  if (is.null(tab1)){
    return(tab2)
  }
  if (is.null(tab2)){
    return(tab1)
  }
  names <- sort(union(names(tab1), names(tab2)))
  
  joined <- rbind(tab1[names], tab2[names])
  colnames(joined) <- names
  
  colSums(joined, na.rm=TRUE)
}

# library(RJSONIO)
# awsKeys <- fromJSON("aws.json")
# options(AmazonS3=c(awsKeys[["key"]]=awsKeys[["secret"]]))

print("Processing each date individually....")
dates <- list.files("download/2014")
pb <- txtProgressBar(min = 0, max = length(dates), style = 3)
dayTbl <- list()
for (i in 1:130){
  d <- dates[[i]]
  path <- paste0("download/2014/", d)
  cs <- list.files(path)
  tbl <- NULL
  for (c in cs){
    allCalls <- read.csv(paste0(path,"/",c))
    callStr <- paste0(allCalls$Block, "|||", allCalls$Street, "|||", allCalls$Zip)
    
    tbl <- joinTables(tbl, table(callStr))
  }
  dayTbl[[d]] <- tbl
  setTxtProgressBar(pb, i)
}
close(pb)

print("Merging dates...")
tbl <- NULL
lengths <- NULL
pb <- txtProgressBar(min = 0, max = length(dayTbl), style = 3)
for (i in 1:length(dayTbl)){
  lengths <- c(lengths, length(tbl))
  tbl <- joinTables(tbl, dayTbl[[i]])
  setTxtProgressBar(pb, i)
}
lengths <- c(lengths, length(tbl))
close(pb)

plot(diff(lengths))
library(lubridate)
lo <- loess(diff(lengths) ~ as.numeric(mdy(paste0(dates,"-2014"))))
lines(1:length(diff(lengths)), lo$fitted, col=2)


