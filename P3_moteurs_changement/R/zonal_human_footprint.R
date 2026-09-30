# library(gdalcubes)
library()
library(knitr)
library(exactextractr)
library(terra)

it_obj = stac("https://io.biodiversite-quebec.ca/stac/") |> 
  collections(collection_id = "hirst-pearson_2022_canadian_human_footprint") |> 
  items() |>
  get_request() |>
  items_fetch()

# it_obj[['features']][[1]]$properties

chf <- rast(paste0('/vsicurl/',it_obj[['features']][[1]]$assets$canadian_human_footprint$href))
# chf |> plot()
source("R/get_qc_maps.R")
# ?st_crop()

## Get zonal stats for Canada
ca = get_canada_admin_reg(crs=chf, format="sf")
ca_zonal = exactextractr::exact_extract(chf, ca, fun="mean")
ca$NAME_1
tibble::tibble(Jurisdiction = ca$NAME_1, CHF = ca_zonal) |>
  readr::write_csv("2_MoteursChangement/Out/Footprint_Canada.csv")

ca$ISO_1


ca$MEAN_HUMAN_FOOTPRINT <- ca_zonal


## Get zonal stats for Quebec
qc = get_qc_regions(crs=chf) 
qc_zonal = exactextractr::exact_extract(chf, qc, fun="mean")

tibble::tibble(Region = qc$RES_NM_REG, CHF = qc_zonal) |>
  readr::write_csv("2_MoteursChangement/Out/Footprint_Quebec.csv")

qc$MEAN_HUMAN_FOOTPRINT <- qc_zonal

## Plots and figures

plot_footprint <- function(df, legend_text) {
  library(ggplot2)
   df |> 
    ggplot(aes(fill = MEAN_HUMAN_FOOTPRINT)) + 
    geom_sf() +
    scale_fill_viridis_c(name = legend_text, option="plasma", limits = c(0.0001, 35))
}

fig_footprint <- function(legend_text = "Empreinte humaine canadienne") {
  library(patchwork)
  plot_footprint(ca, legend_text) + 
  plot_footprint(qc, legend_text) + 
    plot_annotation(tag_levels = "a", tag_suffix = ")") +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom")
}

dir = fs::dir_create("2_MoteursChangement/Fig/")

fig_footprint()
ggsave(fs::path(dir, "footprint_zonal.png"), width = 7, height = 4.5)


fig_footprint("Canadian Human Footprint")
ggsave(fs::path(dir, "footprint_zonal.en.png"), width = 7, height = 4.5)

