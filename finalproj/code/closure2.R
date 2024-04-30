library(sf)

df <- st_read("join_data.geojson")

df <- df[!is.na(df$start), ] ## I took the liberty of getting rid of the NA values

df <- df[!is.na(df$end), ]   ## I took the liberty of getting rid of the NA values

start_date <- as.POSIXct("2018-09-12") ## I did not look at your JS, I just assumed this was the first day

myDates <- seq(start_date, by = "day", length.out = 18) ## this makes a vector of dates starting on start_date 



myGEOIDs = unique(df$GEOID) ## I selected the geoid that you had in this dataset

aList = list() # made an empty list

aList[['geoid']] = myGEOIDs ## added a vector to the list with the name geoid



for (i in 1:length(myDates))
  
{ ## start loop by dates
  
  aResult = NULL
  
  day = myDates[i]
  
  for (geoid in myGEOIDs )
    
  {## start loop by geoids
    
    df1 = df[df$GEOID == geoid & df$start <= day & df$end > day,] # the query for each geoid and day. 
    
    n = nrow(df1) ## calculating how many instances I have of the previous query 
    
    ## so in other words, I have counted how many instances of GEOID are within that time. 
    
    aResult = c(aResult,n) ## I am making a vector that is collecting the results
    
  } ## end loop by geoid
  
  aList[[as.character(myDates[i])]] = aResult ## adding the vector to the list with the name of the date. 
  
} ## end loop by day



df2 <- data.frame(aList) ## make the list into a dataframe


## now you will have to join this dataframe to the geojson with the 100 counties,

df3 <- 

## export the goejson,

## make into a JS, and finally  

## run a similar code to the one I shared in class that changes a choropleth based on the values of the dates in columns 



