## RSelenium

## Installing RSelenium and Getting Started:
## https://cran.r-project.org/web/packages/RSelenium/vignettes/basics.html
## Download the java binary:
## selenium-server-standalone-x.xx.x.jar

library(RSelenium)
library(XML)
## for applying over lists/vectors
library(purrr)
## for some string manipulations - cleaning up scraped data
library(stringr)
## for wrangling data - using mutate_at(), etc.

## create remote driver server and client - using "chrome"
remDr <- rsDriver(browser = "chrome")

## NOTE: If you want to end the selenium server, you must quit RStudio

## extract the client for navigation
rD <- remDr[['client']]

## navigate to page
rD$navigate("http://www.countyhealthrankings.org/app/texas/2018/rankings/marion/county/outcomes/overall/snapshot")

## how to extract data? navigate the DOM
## Let's work on country demographics first
demoTable <- rD$findElement(using = "css", "#main-inner-wrapper > div.ng-scope.demographics > div > table")

demoTableHead <- demoTable$findChildElements(using = "css", "thead > tr > th")

demoTableHeadEntries <- map_chr(demoTableHead, function(t) t$getElementAttribute("innerHTML")[[1]])
## &nbsp; is HTML speak for a 'space'

demoTableRows <- demoTable$findChildElements(using = "css", "tbody > tr")

## 12 rows - confirm with webpage

## proccess a row
demoTableRowEntries <- map(demoTableRows, function(t) {
  entries <- t$findChildElements(using = "css", "td")
  ## first entry has a span and a element within it:
  name <- entries[[1]]$findChildElements(using = 'css', 'a')[[1]]$getElementAttribute("innerHTML")[[1]]
  county <- entries[[3]]$getElementAttribute('innerHTML')[[1]]
  state <- entries[[4]]$getElementAttribute('innerHTML')[[1]]
  return(data.frame(header = name, county = county, state = state))
})

## create larger data.frame to hold results
dfDemo <- do.call('rbind', demoTableRowEntries)
dfDemo

## Notice that removing "%", ",% and converting to numeric would be helpful in 'county', 'state' columns
## using stringr for this:
dfDemo2 <- dfDemo
dfDemo2 <- dfDemo2 %>% mutate_at(2:3, function(t) {
  str_replace_all(t, "%|,", "")
})

dfDemo2


## This becomes more powerful when you go to other pages and take advanatage of the same structure:
## First show navigation using the webpage, then show automation - steps below

## Want to do to things (demonstrate in window):
## (1) Select another state
## (2) Select county within state

## select state select input link
## this takes some time and experimentation
## in general, looking for input and a tags
stateSelectLink <- rD$findElement(using = "css", "#app-main > div.app-header.breadcrumb > div > div.app-state-select.ui-select-container.select2.select2-container.ng-empty.ng-valid > a")

## make search box visible
stateSelectLink$clickElement()

## click the div for the state we want:
rD$executeScript("jQuery('#ui-select-choices-1 > li:contains(\"Nebraska\")').click();")

## select county select input
countySelectLink <- rD$findElement(using = "css", "#main > div.ng-scope > div > a")

## make search box visible
countySelectLink$clickElement()

## change value and update

## click the div for the county we want - more JS:
rD$executeScript("jQuery('#ui-select-choices-3 > li:contains(\"Adams\")').click();")

## now grab demographic again:

demoTable <- rD$findElement(using = "css", "#main-inner-wrapper > div.ng-scope.demographics > div > table")

demoTableHead <- demoTable$findChildElements(using = "css", "thead > tr > th")

demoTableHeadEntries <- map_chr(demoTableHead, function(t) t$getElementAttribute("innerHTML")[[1]])
## &nbsp; is HTML speak for a 'space'

demoTableRows <- demoTable$findChildElements(using = "css", "tbody > tr")

## 12 rows - confirm with webpage

## proccess a row
demoTableRowEntries <- map(demoTableRows, function(t) {
  entries <- t$findChildElements(using = "css", "td")
  ## first entry has a span and a element within it:
  name <- entries[[1]]$findChildElements(using = 'css', 'a')[[1]]$getElementAttribute("innerHTML")[[1]]
  county <- entries[[3]]$getElementAttribute('innerHTML')[[1]]
  state <- entries[[4]]$getElementAttribute('innerHTML')[[1]]
  return(data.frame(header = name, county = county, state = state))
})

## create larger data.frame to hold results
dfDemo <- do.call('rbind', demoTableRowEntries)
dfDemo

## time for a function!
## run after starting selenium server with rsDriver()
extractDemographics <- function(state = "Indiana", county = "Marion")
{
  rD$navigate("http://www.countyhealthrankings.org/app/texas/2018/rankings/marion/county/outcomes/overall/snapshot")
  
  stateSelectLink <- rD$findElement(using = "css", "#app-main > div.app-header.breadcrumb > div > div.app-state-select.ui-select-container.select2.select2-container.ng-empty.ng-valid > a")
  
  ## make search box visible
  stateSelectLink$clickElement()
  
  ## click the div for the state we want:
  rD$executeScript(paste0("jQuery('#ui-select-choices-1 > li:contains(\"", state, "\")').click();"))
  
  Sys.sleep(1)
  ## select county select input
  ## need error catching here
  countySelectLink <- tryCatch({
    rD$findElement(using = "css", "#main > div.ng-scope > div > a")}, 
    error = function(e) {"not found!"})
  
  while (identical(countySelectLink, "not found!"))
  {
    Sys.sleep(1)
    countySelectLink <- tryCatch({
      rD$findElement(using = "css", "#main > div.ng-scope > div > a")
    }, error = function(e) {"not found!"})
  }
  
  ## make search box visible
  countySelectLink$clickElement()
  
  ## change value and update
  
  ## click the div for the county we want - more JS:
  rD$executeScript(paste0("jQuery('#ui-select-choices-2 > li:contains(\"", county, "\")').click();"))
  
  ## now grab demographic again:
  Sys.sleep(1)
  
  ## notice that it takes time to load - can get an error if we're not careful!
  demoTable <- tryCatch(rD$findElement(using = "css", "#main-inner-wrapper > div.ng-scope.demographics > div > table"), error = function(e) {"not found!"})
  
  while(identical(demoTable, "not found!"))
  {
    Sys.sleep(1)
    demoTable <- tryCatch(rD$findElement(using = "css", "#main-inner-wrapper > div.ng-scope.demographics > div > table"), error = function(e) {"not found!"})
  }
  
  demoTableHead <- demoTable$findChildElements(using = "css", "thead > tr > th")
  
  demoTableHeadEntries <- map_chr(demoTableHead, function(t) t$getElementAttribute("innerHTML")[[1]])
  ## &nbsp; is HTML speak for a 'space'
  
  demoTableRows <- demoTable$findChildElements(using = "css", "tbody > tr")
  
  ## 12 rows - confirm with webpage
  
  ## proccess a row
  demoTableRowEntries <- map(demoTableRows, function(t) {
    entries <- t$findChildElements(using = "css", "td")
    ## first entry has a span and a element within it:
    name <- entries[[1]]$findChildElements(using = 'css', 'a')[[1]]$getElementAttribute("innerHTML")[[1]]
    county <- entries[[3]]$getElementAttribute('innerHTML')[[1]]
    state <- entries[[4]]$getElementAttribute('innerHTML')[[1]]
    return(data.frame(header = name, county = county, state = state))
  })
  
  ## create larger data.frame to hold results
  dfDemo <- do.call('rbind', demoTableRowEntries)
  dfDemo
  
}

## testing function
extractDemographics("Indiana", "Hamilton")
extractDemographics("Indiana", "Marion")
extractDemographics("Indiana", "Martin")

## Fun, but what next? We likely want more than demographics

