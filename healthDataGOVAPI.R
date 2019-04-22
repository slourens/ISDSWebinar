library(httr)
library(jsonlite)
## Instead of lapply, purrr can be much faster
library(purrr)
## for string manipulation
library(stringr)

## healthdata.gov/api is open - keys are not necessary to access

## In many cases, one must create a login/app to obtain
## access token and access secrets
## Each API is different in terms of structure, authentication, etc.
## healthdata.gov/api is fairly simple to get started

## We can first identify the datasets we have available
datasets <- GET("https://healthdata.gov/data.json")

## extract content from data.json at healthdata.gov
## provides a structure so we can see what datasets are available
## find a PROGRAMMATIC way of identifying/extracting them
contents <- content(datasets)

## identify the structure in RStudio using the Environment pane
## or our wonderful str() function:
## str(contents)
datasetInfo <- contents$dataset

length(datasetInfo) ## lots of datasets!

## extract their names (titles), descriptions, 
## access URLs (for XML, JSON, separately)
titles <- purrr::map_chr(datasetInfo, function(t) {str_trim(t$title)})
descriptions <- map_chr(datasetInfo, function(t) {t$description})
distributionInfo <- map(datasetInfo, function(t) {t$distribution})

## Find a dataset you're interested in:
View(titles) ## better to write it to a .csv
## write.csv(titles, filePath)

## Value of care - National
indNumber <- which(titles == "Value of care -  National")

## datasetInfo[[1]]$distribution[[3]]$accessURL
dataset <- GET(distributionInfo[[indNumber]][[3]]$accessURL)

## 
DSContents <- content(dataset)

## don't want to lose NULL values - messes up the program later
DSContdat <- map(DSContents$data, function(t) {map(t, function(u) {
  if (is.null(u)) {
    u <- NA
  } else {
    u
  }
})})

DSTab <- as.data.frame(do.call('rbind', map(DSContdat, function(t) unlist(t))))

## notice the additional columns? Let's see if we can figure out why... 
## What do I mean additional columns? Each time you navigate to a web page, you're actually
## conducting a GET request, requesting the content at the URL endpoint you typed into the browser,
## SOOO, let's try the CSV endpoint for the data we're requesting:
## modifying distributionInfo[[indNumber]][[3]]$accessURL to be for csv:
## "https://data.medicare.gov/api/views/gbq5-7hzr/rows.csv?accessType=DOWNLOAD"
## This downloads the file, let's compare DSTab to the csv version

## SO, why the extra columns?
DSContents$meta$view$columns[[1]]$flags ## 'hidden'!
DSContents$meta$view$columns[[9]]$flags ## not there!

## if we navigate to the download link, we can see that these columns aren't in the download
flagsToInclude <- map_lgl(DSContents$meta$view$columns, function(t) {is.null(t$flags)})


DSTab <- DSTab[,flagsToInclude]

## extract names
colNames <- map_chr(DSContents$meta$view$columns, function(t) t$name)
colNames <- colNames[flagsToInclude]
names(DSTab) <- colNames

## Make a function - let's abstract this so you don't need to go through the entire process
## as above - it's a lot to keep straight in a short webinar!
createHDGData <- function(title)
{
  ## can be extended for further types by specifying type argument above
  type <- "json"
  
  ## inefficient but puts everything in one function/area :)
  datasetInfo <- content(GET("https://healthdata.gov/data.json"))$dataset
  distributionInfo <- map(datasetInfo, function(t) {t$distribution})
  indNumber <- which(titles == title)
  if (identical(indNumber, integer(0)))
  {
    stop("Did not find title in the Health Data Gov endpoint: https://healthdata.gov/data.json")
  }
  formats <- map_chr(distributionInfo[[indNumber]], function(t) t$format)
  typeInd <- which(formats == type)
  if (identical(typeInd, integer(0)))
  {
    stop("Did not find specified type/format for this dataset - please try another type. You may consider 'json' as an alternative to 'xml', and vice versa")
  }
  dataset <- GET(distributionInfo[[indNumber]][[typeInd]]$accessURL)
  DSContents <- content(dataset, as = "parsed")
  
  ## don't want to lose NULL values - messes up the program later
  DSContdat <- map(DSContents$data, function(t) {map(t, function(u) {
    if (is.list(u))
    {
      u <- ifelse(is.null(u[[1]]), NA, u[[1]])
    } else {
      if (is.null(u)) {
        u <- NA
      } else {
        u
      }
    }
  })})
  
  ## sometimes throws a warning
  DSTab <- as.data.frame(do.call('rbind', map(DSContdat, function(t) unlist(t))))
  
  ## if we navigate to the download link, we can see that these columns aren't in the download
  flagsToInclude <- map_lgl(DSContents$meta$view$columns, function(t) {is.null(t$flags)})
  
  DSTab <- DSTab[,flagsToInclude]
  
  ## extract names - only those for inclusion
  colNames <- map_chr(DSContents$meta$view$columns, function(t) t$name)
  colNames <- colNames[flagsToInclude]
  names(DSTab) <- colNames
  
  return(DSTab)
}

test <- createHDGData("Medicare Spending Per Beneficiary – Hospital")
test2 <- createHDGData("Payment - National")
test3 <- createHDGData("Inpatient Psychiatric Facility Quality Measure Data – by Facility")
