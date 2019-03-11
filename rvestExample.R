## using rvest for static web content
library(rvest)

## http://www.countyhealthrankings.org
##
## http://www.countyhealthrankings.org/app/texas/2018/rankings/harris/county/outcomes/overall/snapshot


site <- read_html("https://airquality.weather.gov/probe_aq_data.php?city=Indianapolis&state=IN&Submit=Get+Guidance")

//*[@id="query"]/table/tbody/tr[2]/td/table[1]/tbody/tr/td[1]/table

## original xpath from browser - left-hand table
site %>% html_nodes(xpath = "//*[@id='query']/table/tbody/tr[2]/td/table[1]/tbody/tr/td[1]/table")

## modified xpath (removing tbody portions)
site %>% html_nodes(xpath = "//*[@id='query']/table/tr[2]/td/table[1]/tr/td[1]/table")

##site %>% html_node(xpath = "//*[@id='query']/table/tr[2]/td/table[1]/tr/td[1]/table")


## create a dataframe easily with html_table() - any html table should do, for the most part
lhDF <- (site %>% html_nodes(xpath = "//*[@id='query']/table/tr[2]/td/table[1]/tr/td[1]/table"))[[1]] %>% html_table()

## original xpath from browser - right-hand table
site %>% html_nodes(xpath = "//*[@id='query']/table/tbody/tr[2]/td/table[1]/tbody/tr/td[2]/table")

## modified xpath (removing tbody portions)
site %>% html_nodes(xpath = "//*[@id='query']/table/tr[2]/td/table[1]/tr/td[2]/table")

## create a dataframe
rhDF <- (site %>% html_nodes(xpath = "//*[@id='query']/table/tr[2]/td/table[1]/tr/td[2]/table"))[[1]] %>% 
  
  html_table()

## A note on headers - if the developers did things CORRECTLY
## then the first row is a header, i.e. uses <th> tags - we're not so lucky here

## easy enough - just modify the names:
names(lhDF) <- lhDF[1,]
lhDF <- lhDF[-1,]

names(rhDF) <- rhDF[1,]
rhDF <- rhDF[-1,]

## CSS selectors

## notice - html_node() vs html_nodes() - 
## html_node() will only take the first instance
## html_nodes() will take all instances in the page
site %>% html_node(css = "#query > table > tbody > tr:nth-child(2) > td > table:nth-child(2) > tbody > tr > td:nth-child(1) > table")

## modification - took the wrong child...
site %>% html_node(css = "#query > table > tr:nth-child(2) > td > table:nth-child(1) > tr > td:nth-child(1) > table")

lhDFCSS <- site %>% html_node(css = "#query > table > tr:nth-child(2) > td > table:nth-child(1) > tr > td:nth-child(1) > table") %>%
  html_table()

## notice - no need to extract first element, html_node() returns only one element!

