#to create the slope
library(RSAGA)
minpoints <- st_read("minimumpoints.gpkg")
tracks <- readTrack()
raster <- terra::rast("dsm.tif")




sloping <- function(dsm,tracks){


  #points along geometry = PAG
  result <- qgis_run_algorithm(
    algorithm = "native:pointsalonglines",
    INPUT = tracks,
    DISTANCE = distance_points_along_line #in meters e.g. 1
  )
  qgis_extract_output(result)
  pag <- sf::st_as_sf(result)




  #geometry by expression = GBE ## this creates vertical lines on each point of pag and its original path going through it
  #https://gis.stackexchange.com/questions/380361/creating-perpendicular-lines-on-line-using-qgis

  expression <- "extend(\r\n   make_line(\r\n      $geometry,\r\n       project (\r\
        \n          $geometry, \r\n          tobechanged, \r\n          radians(\"angle\"-90))\r\
        \n        ),\r\n   tobechanged,\r\n   0\r\n)"


  profilelengthhalf <- profilelength/2

  newexpression <- gsub('tobechanged', profilelengthhalf, expression)



  #trackRcheck::changelengthofprofile(profilelength)
  upperprofile <- qgis_run_algorithm(
    algorithm = "native:geometrybyexpression",
    INPUT = pag,
    EXPRESSION = newexpression,
    OUTPUT_GEOMETRY = 1
  )






  result <- qgis_run_algorithm(
    algorithm = "native:slope",
    INPUT = dsm,
    Z_FACTOR = 1 #means no exaggeration
  )

  qgis_extract_output(result)
  slope <- sf::st_as_sf(result)




}


bufferedtrack <- sf::st_buffer(tracks, 1, endCapStyle = "ROUND", joinStyle = "ROUND")
plot(bufferedtrack)

# Clip raster by buffer
dsm_clipped <- mask(dsm, bufferedtrack)

slope <- qgis_run_algorithm(
  algorithm = "native:slope",
  INPUT = dsm_clipped,
  Z_FACTOR = 1 #means no exaggeration
)
qgis_extract_output(slope)
slope <- qgis_as_terra(slope)
plot(slope)



pag <- qgis_run_algorithm(
  algorithm = "native:pointsalonglines",
  INPUT = tracks,
  DISTANCE = 1 #in meters
)
qgis_extract_output(pag)
pag <- sf::st_as_sf(pag)

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
gbe[["line_id"]] <- 1:nrow(gbe)#defining line_ad as field
gbe$line_id <- 1:nrow(gbe)#adding line_ad as field to gbe


# SAGA Profile from lines = sagaPFL # NEW title: creating points on vertical lines


sagaPFL <- qgis_run_algorithm(
  algorithm = "native:pointsalonglines",
  INPUT = gbe,
  DISTANCE = 0.005 #in meters
)
qgis_extract_output(sagaPFL)
pfl <- sf::st_as_sf(sagaPFL)
