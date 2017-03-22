library(choroplethrZip)
library(readxl)
library(httr)
library(dplyr)

il_2014 <- 'https://www.irs.gov/pub/irs-soi/14zp14il.xls'
GET(il_2014, write_disk("il.xls", overwrite=TRUE))
il <- read_excel("il.xls", skip = 5)
il <- il[,c(1,2,14,15)]
colnames(il) <- c("zip", "group", "count", 'amount')
il$zip <- as.character(il$zip)

data(df_zip_demographics)
# could also do percent in rows 6 or 7 to get percent above 100k
zip_incomes <- il %>%
  group_by(zip) %>%
  filter(row_number() == 1) %>%
  mutate(avgIncome = amount/count) %>%
  select(-group) %>%
  inner_join(df_zip_demographics, by = c("zip" = "region")) %>%
  na.omit() 


zip_incomes$value = zip_incomes$avgIncome
zip_incomes$region = zip_incomes$zip

zip_choropleth(zip_incomes,
               title       = "2014 Illinois ZIP Code Average Income",
               legend      = "Per Capita Income",
               state_zoom='illinois')


### ********************************************************* ###

# Get the zipfile for the US census zipcodes map
url <- "http://www2.census.gov/geo/tiger/GENZ2013/cb_2013_us_zcta510_500k.zip"
destname <- "uszip.zip"
if (! file.exists(destname)) download.file(url, destname)

# Extract the shapefile
filename <- "cb_2013_us_zcta510_500k.shp"
downloaddir <- getwd()
if (! file.exists(filename)) unzip(destname, exdir=downloaddir, junkpaths=TRUE)
filename <- gsub(".shp", "", filename)

library(rgdal)

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
popup <- paste0("<b>", "Median Rent: ", "</b>", dat.merged$median_rent, "<br>",
                "<b>", "Zip Code: ", "</b>", dat.merged$zip, "<br>",
                "<b>", "Average Income: ", "</b>", 
                dat.merged$avgIncome)

library(leaflet)
# Define a color palette
pal <- colorNumeric(
  palette = "YlOrRd",
  domain = log(dat.merged$avgIncome)
)

# Make the map
map <- leaflet() %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(data = dat.merged, 
              fillColor = ~pal(log(avgIncome)), 
              color = "#b2aeae",
              fillOpacity = 0.7, 
              weight = 1, 
              smoothFactor = 0.2,
              popup = popup) %>%
  addLegend(pal = pal, 
            values = log(dat.merged$avgIncome), 
            position = "bottomright", 
            title = "Average Income",
            labFormat = labelFormat(suffix = "k", transform=exp))

map
