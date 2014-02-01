library(httr)

raw <- POST(url="http://dallaspolice.net/MediaAccess/Default.aspx", 
          body="httprequest=true")
html <- content(raw, useInternalNodes=TRUE)

rows1 <- xpathApply(html, "//table[@id='grdData_ctl01']//tr[@class='GridRow_Mac']", function(n){n})
rows2 <- xpathApply(html, "//table[@id='grdData_ctl01']//tr[@class='GridAltRow_Mac']", function(n){n})
rows <- c(rows1, rows2)

vals <- lapply(rows, xpathApply, './td/node()', function(n){xmlValue(n)})
data <- as.data.frame(t(sapply(vals, rbind)))
colnames(data) <- c("Map", "IncidentNum", "Division", "Nature", "Priority", 
                    "DateTime", "UnitNum", "Block", "Location", "Beat", 
                    "ReportingArea", "Status")
