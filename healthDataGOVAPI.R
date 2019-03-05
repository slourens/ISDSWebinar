library(httr)
library(jsonlite)
library(rHealthDataGov)

## datasets
datasets <- GET("https://healthdata.gov/data.json")

datasets <- fromJSON(datasets)

## test GET


test1 <- GET("https://data.medicaid.gov/api/views/v48d-4e3e/rows.json?accessType=DOWNLOAD")


test <- GET("https://healthdata.gov/api/dataset/")
