

#' Calculating the lowest points along the track
#'
#' @param raster a dsm.tif file
#' @param tracks a sf file
#' @param distance_points_along_line default is 1
#' @param profilelength
#' @param distancecrossprofilepoints


#' @return
#' @export
#'
#' @examples





minpoint <- function(raster, tracks, distance_points_along_line = 1, profilelength = 1, distancecrossprofilepoints = 0.05) {

checkFunction <- function() {
  user_input <- readline("Are you sure your Tracks-Layer provides the needed conditions for this function? (y/n)")
  if(user_input != "y") stop("Exiting since you did not press y")
  print("You can adjust you column names and try again")
}

checkFunction()

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

  # adding the dsm values to the points
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
 pointsandstats <- dplyr::left_join(centerpoints, stats, by = "line_id")


 #select objects where Z value is the same as minimum value (so we only have the minimum object of the profiles)
 selected <- pointsandstats[pointsandstats$z == pointsandstats$min,]

 selected <- selected[,c("class_id","fade_scr","line_id","z","min","stddev","median", "mean")]

 st_write(selected, "minimumpoints.gpkg", driver = "GPKG")



  return("You now have a GPKG Layer with minimumpoints along your track in your outputfolder")

}

