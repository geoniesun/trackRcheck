#creating a map to look at random points to see where you are at

library(ggplot2)
library(sf)
library(terra)

# Step 1: Read your DEM, lines, and points data
dem <- terra::rast("dsm.tif")
lines <- readTrack()
points <- st_read("minimumpoints.gpkg")


# Step 2: Generate random coordinates within your data extent
randompoint <- st_sample(lines, 1)

buffer <- st_buffer(randompoint, 20, enCapStyle = "SQUARE")


# Step 3: Filter your data to a smaller area around the random coordinates

dsm_subset <- crop(dem, buffer)
lines_subset <- st_join(dsm_subset,lines)
lines_subset <- st_join(points,dsm_subset)

# Step 4: Create ggplot object and plot layers

mydataframe <- as.data.frame(dsm_subset, xy=T)%>%
  na.omit()


gg <- ggplot() +
  geom_raster(data = mydataframe, aes(dsm)) +
  geom_path(data = lines_subset, aes(x = longitude, y = latitude)) +
  geom_point(data = points_subset, aes(x = longitude, y = latitude))

# Step 5: Zoom to the area around the random coordinates
gg <- gg + coord_cartesian(xlim = c(random_x - buffer_distance,
                                    random_x + buffer_distance),
                           ylim = c(random_y - buffer_distance,
                                    random_y + buffer_distance))

# Display the plot
print(gg)
