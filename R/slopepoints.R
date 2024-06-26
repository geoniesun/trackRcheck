
slopepoints <- function(raster, tracks, distance_points_along_line = 1, profilelength = 1, distancecrossprofilepoints = 0.05) {

  checkFunction <- function() {
    user_input <- readline("Are you sure your Tracks-Layer provides the needed conditions for this function? (y/n)")
    if(user_input != "y") stop("Exiting since you did not press y. You can adjust you column names and try again")

  }

  checkFunction()

  #first lets make the dsm a bit smaller


  bufferedtrack <- sf::st_buffer(tracks, profilelength, endCapStyle = "ROUND", joinStyle = "ROUND")

  # Clip raster by buffer
  dsm_clipped <- mask(raster, bufferedtrack)

  slope <- qgis_run_algorithm(
    algorithm = "native:slope",
    INPUT = dsm_clipped,
    Z_FACTOR = 1 #means no exaggeration
  )
  qgis_extract_output(slope)
  slope <- qgis_as_terra(slope)


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
  profiles <- qgis_run_algorithm(
    algorithm = "native:geometrybyexpression",
    INPUT = pag,
    EXPRESSION = newexpression,
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
    DISTANCE = distancecrossprofilepoints #in meters
  )
  qgis_extract_output(sagaPFL)
  pfl <- sf::st_as_sf(sagaPFL)

  #buffer around points along vertical lines = BVL
  bufferedpoints <- sf::st_buffer(pfl, 0.001, endCapStyle = "ROUND", joinStyle = "ROUND")

  #join attributes by location

  joinedL <- st_join(bufferedpoints, gbe, left = T)#until here the package worked 25.03.2024

  # recreate center points of buffers to later add the DSM data

  centerpoints <- sf::st_centroid(joinedL)

  # adding the slope values to the points
  slopepoints <- terra::extract(slope,centerpoints)
  centerpoints$slope <- slopepoints[, -1]
  #adding dsm values for bringing it together later
  dsmpoints <- terra::extract(raster,centerpoints)
  centerpoints$z <- dsmpoints[, -1]




  #removing the unnecessary line_id.y.x
  centerpoints <- centerpoints %>%
    dplyr::select(!ends_with("y"))

  centerpoints <-  centerpoints %>%
    dplyr::rename(
      class_id = class_id.x,
      line_id = line_id.x,
      fade_scr = fade_scr.x,
      distance = distance.x,
      angle = angle.x
    )

#here i have to split the upper and down parts
  sidebuff_distance <- profilelength/2

  upbuff <- qgis_run_algorithm(
    algorithm = "native:singlesidedbuffer",
    INPUT = tracks,
    DISTANCE = sidebuff_distance ,
    SIDE = 1,
    SEGMENTS =8,
    JOIN_STYLE=0,
    MITER_LIMIT= 2
  )
  qgis_extract_output(upbuff)
  upbuff <- sf::st_as_sf(upbuff)

  downbuff <- qgis_run_algorithm(
    algorithm = "native:singlesidedbuffer",
    INPUT = tracks,
    DISTANCE = sidebuff_distance ,
    SIDE = 0,
    SEGMENTS =8,
    JOIN_STYLE=0,
    MITER_LIMIT= 2
  )

  qgis_extract_output(downbuff)
  downbuff <- sf::st_as_sf(downbuff)


  upperslope <- st_filter(centerpoints,upbuff)

  downerslope <- st_filter(centerpoints,downbuff)



  #categorial statistics

  upperstats <- qgis_run_algorithm(
    algorithm = "qgis:statisticsbycategories",
    INPUT = upperslope,
    VALUES_FIELD_NAME = "slope",
    CATEGORIES_FIELD_NAME = "line_id"

  )

  downerstats <- qgis_run_algorithm(
    algorithm = "qgis:statisticsbycategories",
    INPUT = downerslope,
    VALUES_FIELD_NAME = "slope",
    CATEGORIES_FIELD_NAME = "line_id"

  )

  su <- qgis_extract_output(upperstats)
  stats_up <- sf::st_as_sf(su)

  sd <- qgis_extract_output(downerstats)
  stats_down <- sf::st_as_sf(sd)




  #join attributs from points layer with dsm info by line_id and min(z)
  slope_up_stats <- dplyr::left_join(upperslope, stats_up, by = "line_id")
  slope_down_stats <- dplyr::left_join(downerslope, stats_down, by = "line_id")






st_write(slope_up_stats, "upperslope.gpkg", append=F)
st_write(slope_down_stats, "downerslope.gpkg", append=F)


#select objects where slope value is the same as max value (so we only have the max slope object of the profiles)
selected_up <- slope_up_stats[slope_up_stats$slope == slope_up_stats$max,]
selected_down <- slope_down_stats[slope_down_stats$slope == slope_down_stats$max,]

selected_up <- selected_up[,c("class_id","fade_scr","line_id","slope","max")]
selected_down <- selected_down[,c("class_id","fade_scr","line_id","slope","max")]

st_write(selected_up, "side1_extent.gpkg", driver = "GPKG")
st_write(selected_down, "side2_extent.gpkg", driver = "GPKG")


}

