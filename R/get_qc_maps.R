download_region_admin <- function(dl_path = "_maps/RegionAdminQC/") {
  dl_path = fs::path_expand(dl_path)
  fs::dir_create(dl_path)
  zip_file = fs::path(dl_path, "SDA.shp.zip")
  utils::download.file("https://diffusion.mern.gouv.qc.ca/diffusion/RGQ/Vectoriel/Theme/Local/SDA_20k/SHP/SDA.shp.zip", 
                destfile = zip_file )
  zip::unzip(zip_file, exdir = dl_path)
}

#' Transform spatial object to match crs of a second object
#' 
#' Function to transform spatial object to match crs of another spatial object
#' @param geom spatial object of type `SpatRaster`, `SpatVector`, `sf`, `sfc`, or `stars` that needs to be transformed
#' @param crs spatial object of type `SpatRaster`, `SpatVector`, `sf`, `sfc`, or `stars` that holds the destination crs for `geom`
#' @returns spatial object of same type as `geom`
#' @export
match_crs <- function(geom, crs) {
  if(!is.null(crs)) {
    # browser()
    is_sf <- function(x) any(class(x) %in% c("sf", "sfc", "stars")) # stars uses sf functions
    is_terra <- function(x) any(class(x) %in% c("SpatVector", "SpatRaster"))
    if( is_sf(geom) && is_sf(crs) ) return( sf::st_transform(geom, sf::st_crs(crs)) )
    if( is_sf(geom)  && is_terra(crs) ) return( sf::st_transform(geom, terra::crs(crs))) # Not tested
    if(   is_terra(geom) && is_sf(crs))    return(terra::project(geom, terra::rast(crs)))
    if(   is_terra(geom) && is_terra(crs)) return(terra::project(geom, crs))
    warning("match_crs() not implemented for object of type ", class(geom), " and/or ", class(crs))
  }
  return(geom)
}

#' Get a multi-polygon of Quebec
#' 
#' Several sources are avaliable to download the multipolygon representation of Quebec (province). 
#' 
#' 
#' @param source A string to describe the source to use for the multipolygon. The default, `"DonneesQuebec"`, downloads a ~90 MB file which can be re-used for `get_qc_regions()` and includes terrestrial and marine areas.
#' 
#' "Fildmaps" uses GeoParquet to extracts a multipolygon including terrestrial (including lakes and rivers) areas of Quebec.
#' 
#' "Ouverture Maps" is similar to fieldmaps, but retreives data from Ouverture Maps.
#' @param crs spatial object which holds CRS that the multiploygon should be transformed into. If NULL, the default, it will keep the source CRS 
#' @returns a `sf` collection.
#' @export
#' 
get_qc_area <- function(source=c("DonneesQuebec", "OuvertureMaps", "fieldmaps"), crs=NULL) {
  source = match.arg(source)
  if(source == "OuvertureMaps") {
    # library(DBI)
    # library(duckspatial)

    ## Get Quebec marine and terrestrial broundry
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "mydb.duckdb")
    
    DBI::dbExecute(con, "INSTALL spatial;  LOAD spatial; INSTALL httpfs; LOAD httpfs; INSTALL json;")
    DBI::dbExecute(con, "
SET VARIABLE latest = (SELECT latest FROM 'https://stac.overturemaps.org/catalog.json');

CREATE OR REPLACE VIEW ds AS SELECT * FROM read_parquet(
    's3://overturemaps-us-west-2/release/'
    || getvariable('latest')
    || '/theme=divisions/type=division_area/*'
) WHERE country = 'CA' AND admin_level = 1 AND names.primary = 'Québec' AND class = 'maritime';
"
    )
    
    out = duckspatial::ddbs_read_table(con, "ds")
  } else if (source == "fieldmaps") {
    # library(DBI)
    # library(duckdb)
    # library(duckdbfs)
    # library(duckspatial)
    
    ## Get quebec terrestrial boundary
    url = "https://data.fieldmaps.io/edge-matched/humanitarian/intl/adm1_polygons.parquet"
    fieldmap_adm1 <- duckdbfs::open_dataset(url) |> 
      duckspatial::as_duckspatial_df(crs=4326)
    # CRS EPSG:4326 according to https://github.com/fieldmaps/edge-extender
    # head(fieldmap_adm1)
    qc_boundry = fieldmap_adm1 |>
      dplyr::filter(adm1_name == "Quebec") |> 
      duckspatial::ddbs_collect() |>
      sf::st_as_sf()
    
    out = qc_boundry
  } else if(source == "DonneesQuebec") {
    dl_path = fs::path_expand("_maps/RegionAdminQC/")
    if(!fs::file_exists("_maps/RegionAdminQC/")) {
      download_region_admin()
    }
    f = fs::path(dl_path, "regio_s.shp")
    df = sf::read_sf(f)
    out = sf::st_combine(df)
  } else {
    stop("Source ", source, " not found.")
  }
  if(!is.null(crs)){
    box::use(lwgeom)
    out = match_crs(out, crs) |>
      sf::st_make_valid()
  }
  out
}

## Testing
# qc_area = get_qc_area(source="OuvertureMaps")
# qc_area = get_qc_area(source="fieldmaps")
# qc_area = get_qc_area(source="DonneesQuebec")

#' @rdname get_qc_area
#' 
#' @description Get multipolygon of south of Quebec (everything below the 49th parallel).
#' @export
get_qc_sud <- function(source=c("DonneesQuebec", "OuvertureMaps", "fieldmaps"), crs=NULL) {
  # library(lwgeom)
  source = match.arg(source)
  sud <- sf::st_polygon(list(sud=matrix(c(-80, 40, -80, 49, -52, 49, -52, 40, -80,40), ncol = 2, byrow = TRUE))) |> 
    sf::st_sfc(crs=4326) |>
    sf::st_segmentize(2000) |> 
    match_crs(crs) |> 
    sf::st_make_valid()
  qc  <- sf::st_make_valid(get_qc_area(source, sud))
  
  sf::st_intersection(qc, sud)
}

# qc_sud = get_qc_sud("fieldmaps")

#' Get Multipolygons for each administrative region of Quebec
#' 
#' Downloads data from Données Québec to _maps folder in project or working directory.
#' 
#' 
#' @export
get_qc_regions <- function(source=c("DonneesQuebec"), crs=NULL) {
  source = match.arg(source)
  if(source == "DonneesQuebec") {
    dl_path = fs::path_expand("_maps/RegionAdminQC/")
    if(!fs::file_exists("_maps/RegionAdminQC/")) {
      download_region_admin()
    }
    f = fs::path(dl_path, "regio_s.shp")
    out = sf::read_sf(f)
  } else {
    stop("Source ", source, " not found.")
  }
  match_crs(out, crs)
}

#' Get administrative regions of Canada
#' 
#' Downloads polygons for each of the provinces and territories of Canada
#' 
#' @param crs spatial object with CRS to match
#' @param format format of returned object
#' @returns spatial object of specified type and CRS with multipolygons for each province and territory of Canada.
#' 
#' @export
get_canada_admin_reg <- function(crs=NULL, format=c("SpatVector", "sf")) {
  format = match.arg(format)
  dir = fs::dir_create("./_maps/geodata")
  can = geodata::gadm(country='CAN', level=1, path=dir)
  if(format == "sf") can <- sf::st_as_sf(can)
  match_crs(can, crs)
}

# can <- get_canada_admin_reg()
# plot(can)
