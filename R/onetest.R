



###load libraries
#define vector of packages to load
some_packages <- c('terra','ggplot2','sf', 'qgisprocess', 'RSAGA', 'Rsagacmd', 'dplyr','remotes')

#load all packages at once
lapply(some_packages, library, character.only=TRUE)


#make this example reproducible
set.seed(0)

#changing layout settings here
setwd("D:/LeonieSonntag/stolsnek/layersinR")
outputpath <- "D:/LeonieSonntag/stolsnek/layersinR"


tiffile <- "D:/LeonieSonntag/stolsnek/dsm_antonio.tif"
layerfile <- "D:/LeonieSonntag/stolsnek/layers/wide_track.gpkg"

#settings
yourcrs <- 32736 #change if needed (32736 is utm 36S)


## import (UAV)-tif

raster <- terra::rast(tiffile)

#import track layer

tracks <- sf::read_sf(layerfile)





minpoint <- function(raster, tracks, distance_points_along_line = 1, myprofilelength = 1, distancecrossprofilepoints = 0.05) {
  
  
  
  
  #points along geometry = PAG
  result <- qgis_run_algorithm(
    algorithm = "native:pointsalonglines",
    INPUT = tracks,
    DISTANCE = distance_points_along_line #in meters e.g. 1
  )
  qgis_extract_output(result)
  pag <- sf::st_as_sf(result)
  
  
  source("D:/LeonieSonntag/stolsnek/scripts/change_expression.R")
  changelengthofprofile(myprofilelength)
  
  expression <- "extend(\r\n   make_line(\r\n      $geometry,\r\n       project (\r\
        \n          $geometry, \r\n          tobechanged, \r\n          radians(\"angle\"-90))\r\
        \n        ),\r\n   tobechanged,\r\n   0\r\n)"
  
  
  #geometry by expression = GBE ## this creates vertical lines on each point of pag and its original path going through it
  #https://gis.stackexchange.com/questions/380361/creating-perpendicular-lines-on-line-using-qgis
  profiles <- qgis_run_algorithm(
    algorithm = "native:geometrybyexpression",
    INPUT = pag,
    EXPRESSION = expression,
    OUTPUT_GEOMETRY = 1
  )
  qgis_extract_output(profiles)
  gbe <- sf::st_as_sf(profiles)
  gbe[["line_id"]] <- 1:nrow(gbe)#defining line_ad as field
  gbe$line_id <- 1:nrow(gbe)#adding line_ad as field to gbe
  
  
  # SAGA Profile from lines = sagaPFL # NEW title: creating points on vertical lines
  
  
  profilepoints <- qgis_run_algorithm(
    algorithm = "native:pointsalonglines",
    INPUT = gbe,
    DISTANCE = distancecrossprofilepoints #in meters
  )
  qgis_extract_output(profilepoints)
  pfl <- sf::st_as_sf(profilepoints)
  
  
  
  #buffer around points along vertical lines = BVL
  bufferedpoints <- sf::st_buffer(pfl, 0.001, endCapStyle = "ROUND", joinStyle = "ROUND")
  
  #join attributes by location
  
  joinedL <- st_join(bufferedpoints, gbe, left = T)
  
  
  
  # recreate center points of buffers to later add the DSM data
  
  
  
}




minpoint(raster, tracks)

centerpoints <- sf::st_centroid(joinedL)
# centerpoints <- sf::st_point_on_surface(joinedL)

# adding the dsm values to the points
dsmpoints <- terra::extract(raster,centerpoints)
centerpoints$z <- dsmpoints[, -1]
