library(jsonlite)
df <- read.csv("finalproj/data/aggregated_closures_06052023.csv")

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
json_data <- toJSON(df2)

# Write JSON to file with .json extension
write(json_data, "finalproj/data.json")