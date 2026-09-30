library(dplyr)
library(terra)
library(sf)
source("R/get_qc_area.R")

## Ecosystem services

dl_path = fs::dir_create("~/Maps/NCPs_Canada/Spatial_Layers")

### Warning: Make sure you have at least 20 GB free space on your system before running the following code.
#   This should not be re-run since the goal is to have it in Biodiversité Quebec's stac catalog
# https://iopscience.iop.org/article/10.1088/1748-9326/abc121/meta

# osfr::osf_retrieve_node("ca43v") |> 
#   osfr::osf_ls_files() |> 
#   filter(name == "Spatial Layers") |> 
#   osfr::osf_ls_files() |> 
#   osfr::osf_download(path=dl_path)

qc_area = get_qc_area(source="DonneesQuebec")
eco_layer_1 <- rast(fs::path(dl_path, "Ecosystem Services", "Carbon", "carbon_total_std.tif"))
qc_area_trans = sf::st_transform(qc_area, sf::st_crs(eco_layer_1))
# fs::dir_create("~/Maps/NCPs_Quebec/Spatial_Layers")

# Crop each layer to Quebec and save 
crop_to_qc <- function() {
  fs::dir_walk(
    dl_path, 
    function(f_path) {
      print(f_path)
      out_path = fs::path_expand(sub("NCPs_Canada", "NCPs_Quebec", f_path, fixed=T))
      if(fs::is_dir(f_path)) {
        fs::dir_create(out_path)
        return()
      } 
      eco_layer <- rast(f_path)
      qc_area_trans = sf::st_transform(
        qc_area_trans, 
        sf::st_crs(eco_layer))
      eco_layer_qc = terra::crop(eco_layer, qc_area_trans, mask=T)
      writeRaster(eco_layer_qc, out_path, overwrite=TRUE)
    },
    recurse = T
  )  
}
crop_to_qc()


## Calculate NCPs at scale of Quebec
qc_path = fs::path_expand("~/Maps/NCPs_Quebec/Spatial_Layers/")


province_est = fs::dir_map(
  qc_path, 
  function(f_path) {
    print(f_path)
    if(fs::is_dir(f_path)) return()
    eco_layer <- rast(f_path)
    global(eco_layer, na.rm=T)
  }, 
  recurse = T
) 

province_wide = province_est |> 
  bind_cols() |> 
  tibble::rownames_to_column() |> 
  tidyr::pivot_wider(names_from = rowname, values_from=mean) |>
  mutate(Region = "Québec (Province)")

## Calculate NCPs per admin region (zonal statistics)

job::job({
  region_est = fs::dir_map(
    qc_path, 
    function(f_path) {
      print(f_path)
      if(fs::is_dir(f_path)) return()
      eco_layer <- rast(f_path)
      qc_regions = get_qc_regions() |> 
        st_transform(sf::st_crs(eco_layer))
      e = exactextractr::exact_extract(eco_layer, qc_regions, fun="mean")
      names(e) = qc_regions$RES_NM_REG
      l = list(e)
      names(l) = names(eco_layer) 
      l
    }, 
    recurse = T
  )
})

out_dir = fs::dir_create("4_NCP/Out/")
region_est |> 
  bind_cols() |> 
  mutate(Region = names(region_est[[3]][[1]]), .before = 1L) |>
  bind_rows(province_wide) |>
  readr::write_csv(fs::path(out_dir, "zonal_means.csv"))


## Plots for three key layers
df = readr::read_csv(fs::path(out_dir, "zonal_means.csv"))
colbind(qc, df )
c(`total_abovebelow_C_aligned_crop_std@study_area`, 
  `water_provision_2a_norm@Water_sensitivity`,
  `recreation_provision_std`, 
  `combined_provision`)

qc
  