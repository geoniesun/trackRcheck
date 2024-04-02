#install packages
install.packages("remotes")
remotes::install_github('RodrigoAgronomia/PAR')
###load libraries
#define vector of packages to load
some_packages <- c('terra','ggplot2','sf', 'qgisprocess', 'RSAGA', 'Rsagacmd', 'dplyr','remotes','tidyverse', 'tidyterra', 'ggnewscale')

#load all packages at once
lapply(some_packages, library, character.only=TRUE)

#make this example reproducible
set.seed(0)


#changing layout settings here
setwd("D:/LeonieSonntag/stolsnek/layersinR")
outputpath <- "D:/LeonieSonntag/stolsnek/layersinR"
