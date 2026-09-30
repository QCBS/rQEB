#################
## Zonal stats ##
#################

#' Get url for an AAFC .tif file for a given year and zone
get_aafc_layer_url <- function(yr, zone) {
  id = paste0("lu", yr, "_u", zone)
  box::use(rstac[...])
  query = stac("https://io.biodiversite-quebec.ca/stac/") |> 
    collections(collection_id = "aafc_land_use") |>
    items(feature_id = id) 
  
  # Access via BQ catalog
  try({
    item = post_request(query)
    return( paste0("/vsicurl/", item$assets[[1]]$href))
  })
  message("Warning: Biodiversité Québec stac catalog is offline")
  
  # Fallback to local copy (if available)
  local_path = fs::path("_maps/land_use_aafc/", yr, id, ext="tif")
  if(fs::file_exists(local_path)) return(local_path)
  
  # Option to download local copy
  stop("Local copy (backup) not avaliable. Try again later, or download data from Agriculture Canada: \n https://agriculture.canada.ca/atlas/data_donnees/landuse/data_donnees/tif/ \n Warning: manual download from Agriculture Canada has not been tested")
}

#' Download AAFC land use data 
#' 
#' Retrieve AAFC land use data via Biodiversité Québec stac catalog
#' and save a local copy of .tif files covering Quebec (untested)
#' @export
dl_aafc_layers <- function() {
  yrs =  c(2000, 2005, 2010, 2015, 2020)
  purrr::map(
    yrs, # Loop over years
    \(yr) {
      purrr::map( # Loop over regions
        17:21, \(zone) { 
          url = get_aafc_layer_url(yr, zone)
          r = terra::rast(url)
          dir_path = fs::path("_maps/land_use_aafc")
          fs::dir_create(dir_path)
          file_path = fs::path(dir_path, fs::path_file(url))
          terra::writeRaster(r, file_path)
        } )
    })
}

#' Calculate zonal land use 
#' 
#' use exactextract to calculate zonal land use:
#' Warning: this function takes at least 30 mins to run
#' I suggest run it as a job (see Example)
#' 
#' The output needs to be summarised over zones to get accurate statistics.
#' This can be done using `summarise_qc_land_use()`
#' 
#' @return dataframe with columns:
#'  `sum` number of raster cells 
#'  `qc_region` Administrative region of Quebec
#'  `year` data collection year
#'  `zone` the raster is split across multiple zones with different 
#'  coordinate reference systms. the zonal stats are calculated for each zone 
#'  independently.
#'  `frac_*` fraction of cells for each type of land use classification
#' 
#' @examples 
#' job::job({ zonal_land_use = calc_zonal_land_uses() })
#' @export
calc_zonal_land_uses =  function(type=c("region_admin", "sud")) {
  box::use(qc_maps = R/get_qc_maps[...])
  yrs =  c(2000, 2005, 2010, 2015, 2020)
  purrr::map(yrs, # Loop over years
      \(yr) {
        print(yr)
        purrr::map( # Loop over regions
          17:21,
          \(zone) {
            print(zone)
            t = terra::rast( get_aafc_layer_url(yr,zone) )
            qc_reg = get_qc_regions(crs=t)
            e = exactextractr::exact_extract(t, qc_reg, "frac")
            s = exactextractr::exact_extract(t, qc_reg, "sum")
            e |> dplyr::mutate(
              sum = s, 
              qc_region =  qc_reg$RES_NM_REG,
              year=yr,
              zone = zone,
              .before=1)
          }) |>
          dplyr::bind_rows()
      }) |>
    dplyr::bind_rows()
}

#' 
calc_qc_sud_land_uses <- function() {
  box::use(qc_maps = R/get_qc_maps[...])
  yrs =  c(2000, 2005, 2010, 2015, 2020)
  purrr::map(yrs, # Loop over years
             \(yr) {
               print(yr)
               purrr::map( # Loop over regions
                 17:20,
                 \(zone) {
                   print(zone)
                   t = terra::rast( get_aafc_layer_url(yr,zone) )
                   qc_reg = get_qc_sud(crs=t)
                   
                   e = exactextractr::exact_extract(t, qc_reg, "frac")
                   s = exactextractr::exact_extract(t, qc_reg, "sum")
                   
                   e |> dplyr::mutate(
                     sum = s, 
                     qc_region =  "Sud de Québec (49e parallèle)",
                     year=yr,
                     zone = zone,
                     .before=1)
                 }) |>
                 dplyr::bind_rows()
             }) |>
    dplyr::bind_rows()
}

#' Summarise output from calc_zonal_land_uses() across zones
#' 
#' @return tibble with:
#'  `qc_region` Administrative region of Quebec
#'  `year` data collection year
#'  `frac_*` fraction of cells for each type of land use classification
#' 
#' @param incl_all_qc Include a summary for the entire province of quebec
#' @export
summarise_qc_land_use = function(df, incl_all_qc=T) {
  box::use(dplyr[mutate, group_by, summarise, across, starts_with, bind_rows]) 
  
  smry  = function(df) { 
    summarise(df, 
      across(starts_with("frac_"), ~stats::weighted.mean(.x, sum, na.rm=T)))
  }
  
  out = df |> 
      group_by(year, qc_region) |>
      smry()
  
  if(incl_all_qc) {
    out = df |> 
      group_by(year) |>
      smry() |> 
      mutate(qc_region = "Québec (province)") |>
      bind_rows(out)
  }
  out
}

#' plot zonal land use
plot_zonal_land_use_over_time <- function(df, class = frac_2, label_position = c("right", "center"), label_cutoff=100, label_shift=0) {
  box::use(ggplot2[aes, ggplot, geom_line, geom_label, scale_color_viridis_d, theme_classic], 
           dplyr[mutate, filter, if_else, across], 
           R/get_fig_styles[...])
  label_position = match.arg(label_position)
  df$val = rowSums(df[class], na.rm=T) * 100
  df$year = as.numeric(df$year)

  add_labels = function() {
    if (label_position == "right") {

      return(
        geom_label(aes(label = qc_region, x= year + label_shift),
                   hjust = 0, 
                   data = df |> filter(year == 2020)) 
      )
    }
    if (label_position == "center") {
      return( 
        geom_label(aes(label = qc_region, y = val + label_shift),
                 data = df |> 
                   filter(year == 2010, val > label_cutoff)) 
        )
    }
  }
  
  df |>
    ggplot(aes(y= val, x=year, group=qc_region, color=qc_region)) +
    geom_line() +
    add_labels() +
    scale_color_viridis_d(option="A", end = 0.8) +
    style_plot()
}

#' Get and cache AAFC land use categorization metadata
#' @export
get_aafc_metadata <- function() {
  
  dir_path = here::here("2_MoteursChangement/Metadata/")
  file_path = fs::path(dir_path, "aafc_landuse_classification_aac_classification_de_utilisation_des_terres.csv")
  
  if(!fs::file_exists(file_path)) {
    fs::dir_create(dir_path) 
    url = "https://agriculture.canada.ca/atlas/data_donnees/landuse/supportdocument_documentdesupport/aafc_landuse_classification_aac_classification_de_utilisation_des_terres.csv"
    readr::read_csv(file = url, locale = readr::locale(encoding = "Latin1")) |>
    readr::write_csv(file_path)
  }
  readr::read_csv(file_path)
}


#' Map IPCC land use categories to AAFC land use codes 
#' (one-to-many) mapping
#' 
#' @param type IPCC land use class
#' @param summary_col_name if true, prepend AAFC land use code with "frac_", 
#' for compatiblity with zonal summary data file.
#' @export
get_aafc_classes <- function(
    type = c("Settlement", "Water", "Forest", "Cropland", "Grassland", "Wetland", "Other Land"), 
    summary_col_name = T
    ) {
  type = match.arg(type)
  df = get_aafc_metadata() |> 
    dplyr::filter(IPCC_Class==type)
  
  message("Code meanings: \n - ", paste(df$Code, df$`Landuse Class`, collapse = "\n - "))
  
  if(summary_col_name) return( paste0("frac_", df$Code) )
  df$Code
}

#' Create and save zonal urban land use figure over time
#' @export
save_urban_land_use_over_time_figures <- function(df, w, h) {
  box::use(ggplot2[...], 
           patchwork[plot_layout, plot_annotation, wrap_elements], 
           grid[unit])
  col_name = get_aafc_classes()

  p1 = 
    plot_zonal_land_use_over_time(
      df, 
      class = col_name, 
      label_cutoff = 10,
      label_shift = 3.5,
      label_position = "center"
    ) + annotate("rect", xmin = 1999.5, xmax = 2020.5, ymin = -1, ymax = 8,
                 alpha = 0, color="#374f2f", linetype = "dashed") + 
    theme(panel.background = element_rect(fill='transparent'), 
          plot.background = element_rect(fill='transparent', color=NA), 
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank()) +
    labs( y = "Utilisation urbaine du territoire (%)" ) 
    
  p2 = 
    wrap_elements(
      full = grid::polylineGrob(
        x = grid::unit(c(-0.48, 1,   -0.48, 1), "npc"), 
        y = grid::unit(c(0.225, 1,     0.13, 0), "npc"), 
        id = c(1,1,2,2), 
        gp=grid::gpar(col="#374f2f", lty = "dotted", lwd = 1.5)), 
      clip=FALSE) 
  
  p3 = 
    plot_zonal_land_use_over_time(
      df, 
      class = col_name, 
      label_shift = 1,
      label_cutoff = 0,
      label_position = "right"
    ) +
    theme(
      plot.background = element_rect(
        fill = "white", 
        color = "#374f2f", 
        linetype="dashed", 
        linewidth=1)
    ) +
    coord_cartesian(ylim=c(0,7.25), clip="off") + 
    theme(plot.margin = margin(l = 5, r=160))  + 
    labs(y=NULL)
  # style_patchwork + 
  
  p1 + ggplot2::ylab("Urban land use (%)") + 
    p2 + p3 + 
    plot_layout(widths = c(1,0.1,1)) & 
    guides(color = "none") &
    ggplot2::xlab("Year")

  ggsave("2_MoteursChangement/Fig/urban_zonal.en.png", width = w, height = h)
  
  p1 + ggplot2::ylab("Affectation urbaine du territoire (%)") + 
    p2 + p3 + 
    plot_layout(widths = c(1,0.1,1)) & 
    guides(color = "none") &
    ggplot2::xlab("Année")
  ggsave("2_MoteursChangement/Fig/urban_zonal.png", width = w, height = h)
}

#' Create and save zonal agricultural land use figure over time
#' @export
save_agri_land_use_over_time_figures <- function(df, w, h) {
  box::use(ggplot2[...])
  col_names = paste0("frac_", get_aafc_classes("Cropland"))
  p1 = plot_zonal_land_use_over_time(df, col_names, label_position = "center", label_cutoff = 15)
  p2 = plot_zonal_land_use_over_time(df, col_names, label_position = "center", label_cutoff = 0) + ylim(0, 10)
  p3 = plot_zonal_land_use_over_time(df, col_names, label_position = "center", label_cutoff = 0) + ylim(0, 2.5)
  p1 + p2 + p3 + ylab("Agricultural land use (%)") & guides(color="none") 
  ggsave("2_MoteursChangement/Fig/agri_zonal.en.png", width = w, height = h)
  
  p1 + p2 + ylab("Utilisation agricole du territoire (%)")
  ggsave("2_MoteursChangement/Fig/agri_zonal.png", width = w, height = h)
}


