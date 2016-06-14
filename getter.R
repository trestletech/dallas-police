library(httr)

raw <- GET(url="https://www.dallasopendata.com/resource/are8-xahz.json")
vals <- content(raw)

library(plyr)
data <- ldply(vals, data.frame)
