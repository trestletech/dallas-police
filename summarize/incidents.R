library(dplyr)
library(readr)
library(lubridate)

Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# TODO: return the last non-NA
Last <- function(x){
  tail(x, n=1)
}

#' This is absurd. But R is falling over when it finds a single-row data.frame, because it
#' KEEPS the tzone attribute on the ReadTime mutation there, but drops it for >1 rows.
#' Dumb.
stripTzone <- function(x){
  attr(x, "tzone") <- NULL
  x
}

summarizeIncidents <- . %>% 
  group_by(Incident) %>% 
  summarize(
    StartTime = min(StartTime),
    EndTime = max(EndTime),
    Division = Mode(Division),
    Nature = Mode(Nature),
    Priority = min(Priority),
    DateTime = Mode(DateTime),
    UnitNum = paste(unique(UnitNum), collapse=","),
    Block = Last(Block),
    Street = Last(Street),
    Beat = Mode(Beat),
    ReportingArea = Mode(ReportingArea),
    UpdateTime = paste(unique(UpdateTime), collapse=","),
    Lat = Last(Lat),
    Long = Last(Long),
    Zip = Last(Zip)
  )

getDay <- function(year, month, day, downloadDir = "../download/"){
  path <- file.path(downloadDir, 
                    year, 
                    paste(
                      sprintf("%02d", month), 
                      sprintf("%02d", day),
                      sep = "-"
                    ))
  files <- list.files(path, pattern="out-\\d+\\.csv", full.names = TRUE)
  
  minutes <- rbind_all(lapply(files, function(f){
    timestamp <- as.integer(sub(".*\\/out-(\\d+)\\.csv", "\\1", f))
    f %>% 
      read_csv(col_types="ccciccicicccddc") %>% 
      mutate(ReadTime = stripTzone(as.POSIXct(timestamp, origin="1970-01-01", tz="UTC")))
  }))
  
  
  day <- minutes %>% 
    group_by(Incident) %>% 
    mutate(StartTime = min(ReadTime), EndTime = max(ReadTime)) %>% 
    summarizeIncidents
  
  day
}

# Version that considers leap-years
days_in <- function(month, year){
  if (month != 2 || year%%4 != 0){
    return(days_in_month(month))
  }
  a <- 29
  names(a) <- "Feb"
  a
}

getMonth <- function(month, year, downloadDir="../download/"){
  days <- 1:days_in(month, year)
  
  path <- file.path(downloadDir,
                    year, 
                    paste(
                      sprintf("%02d", month), 
                      sprintf("%02d", days),
                      sep = "-"
                    ))
  
  # Filter out any days we don't have.
  days <- days[file.exists(path)]
  
  data <- list()
  for (d in days){
    message("\tProcessing day #", d, "/", max(days))
    data[[paste(year, month, d, sep="-")]] <- getDay(year, month, d, downloadDir)
  }
  
  rbind_all(data) %>% summarizeIncidents
}

getYear <- function(year, downloadDir="../download/"){
  validYears <- as.integer(list.files(downloadDir, pattern="20\\d{2}"))
  if (! year %in% validYears){
    stop ("Don't have any data for ", year)
  }
  
  days <- list.files(file.path(downloadDir, year))
  validMonths <- as.integer(unique(sub("(\\d{2})-\\d{2}", "\\1", days)))
  
  data <- list()
  for (m in validMonths){
    message("Processing ", month.name[m], ", ", year)
    data[[paste(m, year, sep="-")]] <- getMonth(m, year, downloadDir)
  }
  
  yr <- rbind_all(data) %>% summarizeIncidents
  
  # Until we better groom the CSVs, we'll post-filter
  # TODO: dplyr-ify
  
  # Only include rows with valid (non-numeric) divisions
  yr <- suppressWarnings({yr[is.na(as.numeric(yr$Division)),]})
  yr <- yr[yr$Incident != "",]
}
