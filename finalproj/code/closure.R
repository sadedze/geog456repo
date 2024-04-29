library(jsonlite)
library(tigris)
library(sf)
library(dplyr)

df <- read.csv("C:/Users/Senam Adedze/OneDrive - University of North Carolina at Chapel Hill/SP2024/GEOG456/aggregated_closures_06052023.csv")

## make text into time
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
joined_data$day <- date <- as.POSIXct(joined_data$day, format = "%m/%d/%Y")

clean <- joined_data %>% 
  group_by(NAME,st) %>%
  filter(st <= st, fn >= fn) %>%
  summarise(total_observations = n_distinct(IncidentID))
