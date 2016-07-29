# Chicago Community Areas Analysis

### age
A shiny app to explore the chicago community areas. More importantly, a test drive of [shinyapps.io](shinyapps.io). 

Data from [some random guy](http://robparal.blogspot.com/2012/05/hard-to-find-census-data-on-chicago.html). No, seriously.

## Setup
Account: andrewmehrmann
PW: Linked through github

`install.packages('rsconnect')`


```
rsconnect::setAccountInfo(name='andrewmehrmann',
			  token='<token>',
			  secret='<SECRET>')
```

## Deploy 

```
setwd("~/gitrepos/chicago/age")
rsconnect::deployApp(appName='Chicago_Age')
```

## Next Steps

* Shapefiles and mapping
* Lookup neighborhoods within community area (scrape wikipedia?)



## Troubleshooting

#### Unable to retrieve package records...
I just reinstalled the trouble packages and viola
			  