#creating a map to look at random points to see where you are at

library(ggplot2)
library(sf)
library(terra)
library(colorspace)

# Step 1: Read your DEM, lines, and points data
dem <- readDSM()
lines <- readTrack()
points <- st_read("minimumpoints.gpkg")


# Step 2: Generate random coordinates within your data extent
randompoint <- st_sample(lines, 1)

buffer <- st_buffer(randompoint, 10, enCapStyle = "SQUARE")


# Step 3: Filter your data to a smaller area around the random coordinates

dsm_subset <- crop(dem, buffer)
dsm_extent <- ext(dsm_subset)
dsm_extent_poly <- as.polygons(dsm_extent, crs = points)
dsm_sf <- sf::st_as_sf(dsm_extent_poly)

lines_subset <- st_crop(lines, dsm_sf)
points_subset <- st_crop(points, dsm_sf)


# Step 4: Create ggplot object and plot layers

dsm_df <- as.data.frame(dsm_subset, xy=T)%>%
  na.omit()


gg <- ggplot() +
  geom_raster(data = dsm_df, aes(x=x, y=y, fill=dsm)) +
  geom_sf(data=lines_subset) +
  geom_sf(data=points_subset) +
theme(
  axis.title.x = element_blank(),
  axis.text.x = element_blank(),
  axis.ticks.x = element_blank(),
  axis.title.y = element_blank(),
  axis.text.y = element_blank(),
  axis.ticks.y = element_blank()) +
  scale_fill_


#Step 5: Hillshade

#estimate the hillshade

sl <- terrain(dsm_subset, "slope", unit = "radians")

# estimate the aspect or orientation
asp <- terrain(dsm_subset, "aspect", unit = "radians")

# calculate the hillshade effect with 45º of elevation
hill <- shade(sl, asp,
                     angle = 45,
                     direction = 300,
                     normalize= TRUE)
# creating the ggplot

hill_sf <- as.data.frame(hill, xy= T)
# Regular gradient
grad <- hypso.colors(10, "dem_poster")

my_lims <- minmax(dsm_subset) %>% as.integer() + c(-2, 2)

ggplot() +
  geom_raster(data=hill_sf, aes(x,y, fill = hillshade), show.legend = FALSE) +
  scale_fill_distiller(palette = "Greys") +
  new_scale_fill() +
  geom_raster(data = dsm_df, aes(x,y, fill = dsm), alpha = 0.7) +
  #scale_fill_gradientn(colours = grad, na.value = NA)
  #scale_fill_hypso_tint_c(palette = "viridis", limits = my_lims) +
 #scale_fill_viridis_c(option = "plasma") +
  scale_fill_continuous_sequential(palette="lajolla", na.value = NA) +
  #scale_fill_gradient(low = "yellow", high = "brown", na.value = NA)+
    guides(fill = guide_colorsteps(barwidth = 21,
                                barheight = .5,
                                title.position = "right",
                                show.limits =F,
                                even.steps = T,
                                reverse = F
                                )) +
  labs(fill = "m", title = "Overview of what is going on") +
  #coord_sf() +
  theme(legend.position = "bottom") +
  geom_sf(data=lines_subset) +
  geom_sf(data=points_subset) +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()) +
  theme(legend.position = "bottom")


