# load libraries 
library(jsonlite)
library(tigris)
library(sf)
library(dplyr)

df <- read.csv("../data/aggregated_closures_06052023.csv")

## format start and end into time
df$st <- as.POSIXct(df$start, format = "%Y-%m-%dT%H:%M:%SZ")
df$fn <- as.POSIXct(df$end, format = "%Y-%m-%dT%H:%M:%SZ")

my_start <- as.POSIXct("2018-09-07T00:00:00Z", format = "%Y-%m-%dT%H:%M:%SZ")
my_end <- as.POSIXct("2018-09-30T00:00:00Z", format = "%Y-%m-%dT%H:%M:%SZ")
my_na <- as.POSIXct("2019-09-30T00:00:00Z", format = "%Y-%m-%dT%H:%M:%SZ")

df2 <- df[df$st >= my_start & df$st <= my_end & df$fn <= my_na, ]
df2$t <- as.numeric(difftime(df2$st, my_start, units = "days"))
df2$te <- as.numeric(difftime(df2$fn, my_start, units = "days"))

# Convert data to JSON
#json_data <- toJSON(df2)

# Write JSON to file with .json extension
#write(json_data, "finalproj/data.json")

# read in nc county shapefile
nc_cty <- counties(state = "NC")

# pts to shapefile
pts_sf <- st_as_sf(df2, coords = c("Longitude", "Latitude"), crs = 4326)

#spatial join
joined_data <- st_join(nc_cty, pts_sf, join = st_intersects) 

# day formatting
joined_data$day <- as.POSIXct(joined_data$day, format = "%m/%d/%Y")

clean <- joined_data %>% 
  group_by(NAME,day(st)) %>%
  filter(st <= day(st), fn >= day(fn)) %>%
  summarise(total_observations = n_distinct(IncidentID))

date.range <- c()
geoids <- unique(nc_cty$GEOID)


for (j in 1:length(date.range)) {
  for (i in 1:100) {
    i = 1
    j = 1
    day = date.range[j]
    geoid = nc_cty$GEOID[i]
    df3 = joined_data[joined_data$st <= day & joined_data$fn > day & joined_data$GEOID == geoid,]
    n = nrow(df3)
    myColumnName = paste0('x',j)
    nc_cty[myColumnName][i,] = n
  }
}

# run through geoids without geometry (df not sf object)
# date range, recognized as date 
# export as json 
# each column has different date, different style for each column

# Create a vector of dates from September 12th to September 29th
dates <- seq(as.Date("2018-09-12"), as.Date("2018-09-29"), by = "day")

# Convert the dates to POSIXct format with the specified format
date.range <- as.POSIXct(dates, format = "%m/%d/%Y")

st_write(joined_data, "join_data.geojson", driver = "GeoJSON")
