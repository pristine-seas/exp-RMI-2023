library(tidyverse)

exp_Gdrive <- "~/marine.data.science@ngs.org - Google Drive/My Drive/Pristine Seas/SCIENCE/expeditions/RMI-2023"

exp_dir <- "/Volumes/RMI-2023/data/primary/raw"
sub_dir <- "/Volumes/RMI-sub/"
NAS_dir <- "/Volumes/exp-RMI-2023/"

list.dirs(NAS_dir)

# 

# Create dirs

paste0(file.path(exp_dir, "bruvs/deployments/",
       "RMI-bruvs")) %>% 
  paste(as.vector(outer(formatC(seq(67,69), width = 2, flag = 0),
                        c("L", "R"), 
                        paste0)),
        sep = "-") %>% 
  purrr::map(dir.create)


#### Meta map

bruvs <- readxl::read_xlsx(file.path(exp_dir, "bruvs/RMI_2023_bruvs_fieldbook.xlsx")) %>% 
  select(ps_station_id, lat, lon, location) %>% 
  mutate(method = "Benthic BRUVs")

sub <- readxl::read_xlsx(file.path(sub_dir, "RMI_sub_metadata.xlsx")) %>% 
  janitor::clean_names() |> 
  mutate(across(c(ends_with("longitude"), ends_with("latitude")) ,
                ~str_remove_all(., "N|W|E|S") |> 
                  str_trim() |> 
                  str_squish() |> 
                  str_replace_all(pattern = "\\'", replacement =  " "))) |> 
  rowwise() |> 
  mutate(across(c(ends_with("longitude"), ends_with("latitude")),
                ~measurements::conv_unit(., from = 'deg_dec_min', to = 'dec_deg') |> 
                  as.numeric() |> 
                  round(digits = 4))) |> 
  select(ps_station_id, lat = bottom_start_latitude, lon = bottom_start_longitude, location) %>% 
  mutate(method = "Submersible survey")

uvs <- readxl::read_xlsx(file.path(NAS_dir,
                                   "data/primary/fish/RMI_2023_fish_fieldbook_AMF.xlsx")) %>%
  select(ps_station_id = ps_site_id, lat, lon, location = island) %>%
  mutate(method = "Underwater visual survey") |> 
  mutate(ps_station_id = str_replace(ps_station_id, "UVS", "uvs"),
         ps_station_id = str_replace(ps_station_id, "s_", "s_0"))

dscm <- readxl::read_xlsx(file.path(NAS_dir,
                                    "data/primary/dscm/RMI_2023_dscm_fieldbook.xlsx")) %>%
  select(ps_station_id, lat = lat_in, lon = lon_in, location) %>%
  mutate(method = "Deep sea cameras",
         location = if_else(location == "Bokok", "Bokak", location))

edna <- readxl::read_xlsx(file.path(NAS_dir,
                                    "data/primary/edna/RMI_2023_edna_fieldbook.xlsx")) |> 
  select(ps_station_id, paired_station_id, water_liters) |> 
  left_join(uvs, by = c("paired_station_id" = "ps_station_id")) |> 
  mutate(method = "e-DNA") |> 
  select(ps_station_id, lat , lon , location, method)

# Vegetation

veg <- readxl::read_xlsx(file.path(NAS_dir,
                                    "data/primary/vegetation/vegetation_surveys.xlsx")) %>%
  mutate(method = "Vegetation survey") |> 
  select(ps_station_id, lat , lon , location, method) 

# Birds

bird_tracks <- list.files(path=file.path(exp_dir,
                          "birds/Transect ebird GPS tracks"), 
           pattern=".+\\.gpx", 
           full.names=TRUE) |> 
  map_dfr(.f = sf::st_read, layer = "tracks")

bird_tracks |> 
  sf::st_write(file.path(exp_dir, "birds/tracks.shp"), append = F)

birds <- readxl::read_xlsx(file.path(exp_dir,
                                     "birds/RMI_2023_birds_fieldbook.xlsx")) %>%
  janitor::clean_names() |> 
  mutate(method = "Bird survey") |> 
  select(ps_station_id = transect, location, lat = lat_start, lon = long_start, method)

pcam <- readxl::read_xlsx(file.path(exp_dir,
                                    "pelagics/RMI_2023_pelagics_fieldbook.xlsx")) %>%
  janitor::clean_names() %>%
  select(ps_station_id = string, lat = lat_in, lon = long_in, location) %>%
  mutate(method = "Pelagic BRUVs") |> 
  filter(!is.na(ps_station_id))

worktable <- bind_rows(bruvs, sub, uvs, dscm, edna, veg, birds, pcam) |> 
  filter(location %in% c("Bikar", "Bokak", "Bikini", "Rongerik")) |> 
  group_by(location, method) |> 
  summarise(n_stations = n_distinct(ps_station_id)) |> 
  pivot_wider(names_from = location, values_from = n_stations) 

tbl <- worktable |> 
  gt::gt(rowname_col = "method") |> 
  gt::tab_header(title = "Number of workstations by island")
  
gt::gtsave(data = tbl, filename = "workstations.png")

tmp <- bind_rows(bruvs, sub, uvs, dscm, edna, veg, birds, pcam) %>% 
  filter(!is.na(lat)) |> 
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

tmp |> 
  sf::st_write(file.path(exp_Gdrive, 
                         "data/primary/processed/exp_stations.shp"), 
               append = F)
