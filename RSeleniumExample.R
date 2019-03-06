## RSelenium

## Installing RSelenium and Getting Started:
## https://cran.r-project.org/web/packages/RSelenium/vignettes/basics.html
## Download the java binary:
## selenium-server-standalone-x.xx.x.jar

library(RSelenium)

## create remote driver server and client - using "chrome"
remDr <- rsDriver(browser = "chrome")

## extract the client for navigation
rD <- remDr[['client']]

## navigate to page
rD$navigate("http://www.countyhealthrankings.org/app/texas/2018/rankings/marion/county/outcomes/overall/snapshot")

## how to extract data? navigate the DOM

