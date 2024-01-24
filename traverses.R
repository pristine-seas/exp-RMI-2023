library(tidyverse)

exp_dir <- "/Volumes/RMI-2023/data/primary/raw"

NAS_dir <- "/Volumes/exp-RMI-2023/"


# Traverse 18

t18_waypoints <- readxl::read_excel(file.path(NAS_dir, "data/primary/traverses/Traverse 18/ground_waypoints.xlsx"))

t18_waypoints |> 
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) |> 
  sf::write_sf(file.path(file.path(NAS_dir, "data/primary/traverses/Traverse 18/ground_waypoints.shp")))

# Traverse 19

JSM_points <- readxl::read_excel(file.path(NAS_dir, "data/primary/traverses/Traverse 19/JSM_waypoints.xlsx"))

JSM_points |> 
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) |> 
  sf::write_sf(file.path(file.path(NAS_dir, "data/primary/traverses/Traverse 19/JSM_waypoints.shp")))

# Traverse 22

t22_waypoints <- readxl::read_excel(file.path(NAS_dir, 
                                              "data/primary/traverses/Traverse 22/traverse_22_gps_waypoints.xlsx"))

t22_waypoints |> 
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) |> 
  sf::write_sf(file.path(file.path(NAS_dir, "data/primary/traverses/Traverse 22/t22_waypoints.shp")))
