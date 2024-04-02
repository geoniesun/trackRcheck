#importing the raster for the DSM information

#' Import DSM raster
#'
#' @param yourDSMpath
#'
#' @return
#' @export
#'
#' @examples
readDSM <- function(yourDSMpath = "C:/eagle/trackRcheck/exampledata_noupload/dsm.tif") {

  if(!file.exists(yourDSMpath)) stop("DSM file does not exist. The file you tried to import: ", yourDSMpath, call = FALSE)
  #TASK: converting to tif to be included here
  if(!grep("tif", yourDSMpath)) stop("Your chosen DSM file is not in GEOTIFF format and must be convertet first")

  format <- if(grepl("tif", yourDSMpath)) "TIFF"

  if(format == "TIFF") {
    message("Next step will be easier if you named the output as 'raster'. If you did already, great!")

    dsm <- terra::rast(yourDSMpath)

  }




}
dsm <- readDSM()
raster <- readDSM()
