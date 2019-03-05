## using rHealthDataGov package
library(rHealthDataGov)

## there's essentially one function you should need:

## package documentation
## https://cran.r-project.org/web/packages/rHealthDataGov/rHealthDataGov.pdf

## fetch_healthdata

## object resources shows what datasets are available
resources$resource

test <- fetch_healthdata(resources$resource[1])

## This doesn't seem to work - possible that it's out of date and needs updated
## Question to webinar - has anyone used this?


