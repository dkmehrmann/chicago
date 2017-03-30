# devtools::install_github('rstudio/leaflet')

library(choroplethrZip)
library(readxl)
library(httr)
library(dplyr)
library(leaflet)
library(rgdal)
library(reshape2)
library(htmlwidgets)

data(df_zip_demographics)

# il_2014 <- 'https://www.irs.gov/pub/irs-soi/14zp14il.xls'
# GET(il_2014, write_disk("il.xls", overwrite=TRUE))
# il <- read_excel("il.xls", skip = 5)
# il <- il[,c(1,2,14,15)]
# colnames(il) <- c("zip", "group", "count", 'amount')
# il$zip <- as.character(il$zip)
# rows that arent all na
# il <- il[rowSums(is.na(il)) < 4,]
# il[is.na(il)] <- "Total"
# zip_incomes <- melt(il, id=c('zip', 'group')) %>%
# dcast(formula=zip ~ group + variable, fun.aggregate=mean) %>%
#   mutate(avgIncome = Total_amount/Total_count) %>%
#   mutate(pctAbove100 = (`$100,000 under $200,000_count` + `$200,000 or more_count`) / Total_count) %>%
#   inner_join(df_zip_demographics, by = c("zip" = "region")) 

us_2014 <- 'https://www.irs.gov/pub/irs-soi/14zpallagi.csv'
GET(us_2014, write_disk("us.csv", overwrite=TRUE))
us <- read.csv("us.csv")
us <- us %>% select(zipcode, agi_stub, N1, A00100)
colnames(us) <- c("zip", "group", "count", 'amount')
us$zip <- as.character(us$zip)
melted <- melt(us, id=c('zip', 'group')) 
melted$group <- as.character(melted$group)

us_totals <- melted %>% 
  group_by(zip, variable) %>%
  summarise(value = sum(value))
us_totals$group <- 'Total'
us_totals$zip <- as.character(us_totals$zip)


zip_incomes <- melted %>% 
  bind_rows(us_totals) %>%
  dcast(formula=zip ~ group + variable, fun.aggregate=mean) %>% 
  mutate(avgIncome = Total_amount/Total_count) %>%
  mutate(pctAbove100 = (`5_count` + `6_count`) / Total_count) %>%
  inner_join(df_zip_demographics, by = c("zip" = "region")) 




### ***************** Deal with Shapefile **************************** ###

# Get the zipfile for the US census zipcodes map
url <- "http://www2.census.gov/geo/tiger/GENZ2013/cb_2013_us_zcta510_500k.zip"
destname <- "uszip.zip"
if (! file.exists(destname)) download.file(url, destname)

# Extract the shapefile
filename <- "cb_2013_us_zcta510_500k.shp"
downloaddir <- getwd()
if (! file.exists(filename)) unzip(destname, exdir=downloaddir, junkpaths=TRUE)
filename <- gsub(".shp", "", filename)

# Read in shapefile (NAD83 coordinate system)
dat <- readOGR(downloaddir, filename) 


# Subset for only those zipcodes in health reform dataset
dat.sub <- dat[dat$ZCTA5CE10 %in% unique(zip_incomes$zip),]

# Transform to EPSG 4326 - WGS84 (required)
dat.trans <- spTransform(dat.sub, CRS("+init=epsg:4326"))

# Save the data slot
dat.data <- dat.trans@data[,c("GEOID10", "ZCTA5CE10")]

# Create a SpatialPolygonsDataFrame (needed to create geojson)
dat.spdf <- SpatialPolygonsDataFrame(dat.trans, data=dat.data)

# Merge health indicator data with map data
dat.merged <- tigris::geo_join(dat.spdf, zip_incomes, "ZCTA5CE10", "zip")

# Define the popup messages
popup <- paste0("<b>", "Median Rent: ", "</b>$", dat.merged$median_rent, "<br>",
                "<b>", "Zip Code: ", "</b>", dat.merged$zip, "<br>",
                "<b>", "Percent above 100k: ", "</b>", 100*round(dat.merged$pctAbove100, 2), "%<br>",
                "<b>", "Average Income: ", "</b>$", round(dat.merged$avgIncome, 0), "k")


# Define a color palette
pal <- colorNumeric(
  palette = "YlOrRd",
  domain = dat.merged$pctAbove100
)

# Make the map
map <- leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = dat.merged, 
              fillColor = ~pal(pctAbove100), 
              color = "#b2aeae",
              fillOpacity = 0.4, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup,
              highlightOptions = highlightOptions(
                color='#ff0000', opacity = 1, weight = 0, fillOpacity = .7,
                bringToFront = TRUE, sendToBack = TRUE)) %>%
  addLegend(pal = pal, 
            values = dat.merged$pctAbove100, 
            position = "bottomright", 
            title = "Percent above 100k",
            labFormat = labelFormat(suffix = "%", transform=function(x) 100*x))


saveWidget(map, file="map.html")


