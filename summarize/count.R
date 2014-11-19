
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
for (i in 1:length(dates)){
  d <- dates[[i]]
  path <- paste0("download/2014/", d)
  cs <- list.files(path)
  tbl <- NULL
  for (c in cs){
    allCalls <- read.csv(paste0(path,"/",c))
    callStr <- paste0(allCalls$Block, "|||", allCalls$Street)
    
    tbl <- joinTables(tbl, table(callStr))
  }
  dayTbl[[d]] <- tbl
  setTxtProgressBar(pb, i)
}
close(pb)


mergeJoin<-function(A) {
  if(length(A)>1) {
    q <- ceiling(length(A)/2)
    a <- mergeJoin(A[1:q])
    b <- mergeJoin(A[(q+1):length(A)])
    joinTables(a, b)
  } else {
    table(names(A[[1]]))
  }
}

mtbl <- mergeJoin(dayTbl)
print (length(mtbl))


print("Merging dates...")
tbl <- NULL
lengths <- NULL
pb <- txtProgressBar(min = 0, max = length(dayTbl), style = 3)
for (i in 1:length(dayTbl)){
  lengths <- c(lengths, length(tbl))
  tbl <- joinTables(tbl, dayTbl[[i]])
  plot(diff(lengths), main=paste0("Plot of first ", length(lengths)))
  setTxtProgressBar(pb, i)
}
lengths <- c(lengths, length(tbl))
close(pb)


dt <- mdy(paste0(dates[1:(length(lengths)-1)],"-2014"))
dl <- diff(lengths)

plot(dt, diff(lengths))
library(lubridate)
lo <- loess(diff(lengths) ~ as.numeric(mdy(paste0(dates[1:(length(lengths)-1)],"-2014"))))
lines(dt, lo$fitted, col=2)

#dtn <- as.numeric(dt)
#lmd <- lm(log(dl) ~ dtn)
#datePts <- seq(from = min(dt), to=max(dt), length.out = 100)
#dfPts <- data.frame(dtn = as.numeric(datePts))
#lmPts <- predict(lmd, dfPts)
#lines(datePts, exp(lmPts), col=3)
#df <- data.frame(dtn = as.numeric(mdy("12/1/2014")))
#exp(predict(lmd, df))

save.image("results.Rdq")

