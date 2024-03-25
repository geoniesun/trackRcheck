#install packages
install.packages("remotes")
remotes::install_github('RodrigoAgronomia/PAR')
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

uavtif <- terra::rast(tiffile)

#import track layer

track <- sf::read_sf(layerfile)



##profiles from lines

#points along geometry = PAG
result <- qgis_run_algorithm(
  algorithm = "native:pointsalonglines",
  INPUT = track,
  DISTANCE = 1 #in meters
)
qgis_extract_output(result)
pag <- sf::st_as_sf(result)
plot(sf::st_geometry(pag))
sf::write_sf(pag, "PAG.gpkg", driver = "GPKG")
sf::write_sf(pag, "PAG.shp")


#geometry by expression = GBE

profiles <- qgis_run_algorithm(
  algorithm = "native:geometrybyexpression",
  INPUT = pag,
  EXPRESSION = "extend(\r\n   make_line(\r\n      $geometry,\r\n       project (\r\
        \n          $geometry, \r\n          1.0, \r\n          radians(\"angle\"-90))\r\
        \n        ),\r\n   1.0,\r\n   0\r\n)",
  OUTPUT_GEOMETRY = 1
)

qgis_extract_output(profiles)
gbe <- sf::st_as_sf(profiles)
plot(sf::st_geometry(gbe))
sf::write_sf(gbe, "GBE.gpkg", driver = "GPKG")
sf::write_sf(gbe, "GBE.shp")

gbe[["line_id"]] <- 1:nrow(gbe) #adding line_ad as field
gbe$line_id <- 1:nrow(gbe)

# SAGA Profile from lines = sagaPFL


sagaPFL <- qgis_run_algorithm(
  algorithm = "native:pointsalonglines",
  INPUT = gbe,
  DISTANCE = 0.05 #in meters
)
qgis_extract_output(sagaPFL)
pfl <- sf::st_as_sf(sagaPFL)
plot(sf::st_geometry(pfl))
sf::write_sf(pfl, "PFL.gpkg", driver = "GPKG")
#sf::write_sf(pfl, "PFL.shp")

#buffer around points along vertical lines = BVL
bufferedpoints <- sf::st_buffer(pfl, 0.0001, endCapStyle = "ROUND", joinStyle = "ROUND")

#join attributes by location

joinedL <- st_join(bufferedpoints, gbe, left = T)
sf::write_sf(joinedL, "joinedL.gpkg", driver = "GPKG")

# recreate center points of buffers to later add the DSM data

centerpoints <- sf::st_centroid(joinedL)
sf::write_sf(centerpoints, "centerpoints.gpkg", driver = "GPKG")

# adding the dsm values to the points
 dsmpoints <- terra::extract(uavtif,centerpoints)
 centerpoints$z <- dsmpoints[, -1]
 
#categorial statistics

 catstats <- qgis_run_algorithm(
   algorithm = "qgis:statisticsbycategories",
   INPUT = centerpoints,
   VALUES_FIELD_NAME = "z",
   CATEGORIES_FIELD_NAME = "line_id"

 )
 s <- qgis_extract_output(catstats)
 stats <- sf::st_as_sf(s)
 
 #join attributs from points layer with dsm info by line_id and min(z)
 pointsandstats <- dplyr::left_join(centerpoints, stats, by = "line_id" == "line_id")
 

#select objects where Z value is the same as minimum value (so we only have the minimum object of the profiles)
selected <- filter(pointsandstats, pointsandstats$z == pointsandstats$min)
#if neded activate for stddev #selected <- filter(selected, selected$stddev>0.1)
selected <- selected[,c("class_id.x","fade_scr.x","line_id","z","min","stddev")]
colnames(selected) <- c("class_id","fade_scr","line_id","z","min_z","stddev") 
st_write(selected, "minimumpoints.gpkg", driver = "GPKG")


#CL = create lines along minimum middle points to later select the left and right side. So then we get the Quantiles

centerline <- 

 
##some help
qgis_algorithms() #which algorithms
qgis_show_help("qgis:statisticsbycategories")
qgis_search_algorithms(algorithm = "statistics")
