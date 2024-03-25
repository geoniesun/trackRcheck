#geometry by expression = GBE ## this creates vertical lines on each point of pag and its original path going through it

expression <- "extend(\r\n   make_line(\r\n      $geometry,\r\n       project (\r\
        \n          $geometry, \r\n          tobechanged, \r\n          radians(\"angle\"-90))\r\
        \n        ),\r\n   tobechanged,\r\n   0\r\n)"

changelengthofprofile <- function(profilelength){
  profilelengthhalf <- profilelength/2
  gsub('tobechanged', 'profilelengthhalf', expression)
}

#https://gis.stackexchange.com/questions/380361/creating-perpendicular-lines-on-line-using-qgis



