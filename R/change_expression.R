#geometry by expression = GBE ## this creates vertical lines on each point of pag and its original path going through it



changelengthofprofile <- function(profilelength){

  expression <- "extend(\r\n   make_line(\r\n      $geometry,\r\n       project (\r\
        \n          $geometry, \r\n          tobechanged, \r\n          radians(\"angle\"-90))\r\
        \n        ),\r\n   tobechanged,\r\n   0\r\n)"


  profilelengthhalf <- profilelength/2
  newexpression <- gsub('tobechanged', profilelengthhalf, expression)

  return(newexpression)
}

#https://gis.stackexchange.com/questions/380361/creating-perpendicular-lines-on-line-using-qgis



