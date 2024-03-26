#' Title
#'
#' @param yourTracksPath
#'
#' @return
#' @export
#'
#' @examples
readTrack <- function(yourTracksPath = "C:/eagle/trackRcheck/exampledata_noupload/testtrack.gpkg") {

  if(!file.exists(yourTracksPath)) stop("Track file does not exist. The file you tried to import: ", yourTracksPath, call = FALSE)
  #TASK: converting to gpkg to be included here
  if(!grep("gpkg", yourTracksPath)) stop("Your chosen Track file is not in the right format and must be convertet first")

  format <- if(grepl("gpkg", yourTracksPath)) "GPKG"

  if(format == "GPKG") {

   thetracks <-  sf::read_sf(yourTracksPath)

   # Check column names
   if (all(colnames(thetracks) %in% c("class_id", "fade_scr", "geom"))) {
     message("Next step will be easier if you named the output as 'tracks'. If you did already, great!")
     return(thetracks)
   } else {
     message("Column names are not as expected. They can be changed but need to be already in this order:")
     adjust_names <- readline(prompt = "Do you want to adjust the column names? (y/n): ")
     if (tolower(adjust_names) == "y") {
       new_colnames <- c("class_id", "fade_scr", "geom")
       colnames(thetracks) <- new_colnames
       message("You successfully changed your column names.")
       return(thetracks)
     } else {
       stop("Exiting. Please make sure the column names match the expected names.")
     }


     }
   }





  }





tracks <- readTrack()
testtrack <- tracks





testtrack <-  testtrack %>%
  dplyr::rename(
    line_id.x = class_id,
    fade_scr.x = fade_scr,
    geometry = geom

  )

st_write(testtrack, "testtrack.gpkg")
