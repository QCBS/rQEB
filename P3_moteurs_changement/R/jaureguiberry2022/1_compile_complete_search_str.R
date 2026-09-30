ebv_srch_gen_df <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/jaureguiberry2022/EBV_general.csv"
))

ebv_srch_ind_df <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/jaureguiberry2022/Table_S1.csv"
))

ebv_srch_df <- dplyr::bind_rows(ebv_srch_gen_df, ebv_srch_ind_df) |>
  dplyr::rename("ebv_srch_str" = "Partial search strings") |>
  dplyr::select(`EBV class`, Indicator, ebv_srch_str)

driver_srch_df <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/jaureguiberry2022/Table_S2.csv"
))

driver2_srch_df <- combn(driver_srch_df$`Partial search strings`, 2) |>
  t() |>
  tibble::as_tibble() |>
  dplyr::left_join(driver_srch_df, by = c("V1" = "Partial search strings")) |>
  dplyr::rename(driver1 = `Human-caused drivers`) |>
  dplyr::left_join(driver_srch_df, by = c("V2" = "Partial search strings")) |>
  dplyr::rename(driver2 = `Human-caused drivers`) |>
  dplyr::mutate(driver_srch_str = glue::glue("({V1}) AND ({V2})")) |>
  dplyr::select(-V1, -V2) |>
  dplyr::bind_rows(tibble::tibble_row(
    driver1 = "General",
    driver2 = NA,
    driver_srch_str = '(driver* OR factor* OR determinant* OR "driving force*" OR threat* OR "proximate cause*" OR pressure* OR stressor* OR risk* OR "global change") AND (multi* OR quantif* OR compar* OR partition* OR rank* OR order* OR relative OR interact* OR interplay* OR synerg* OR magnitude* OR rate* OR effect* OR impact* OR influe* OR pace* OR extent OR importan*)'
  ))


complete_srch_df <- tidyr::expand_grid(driver2_srch_df, ebv_srch_df) |>
  dplyr::mutate(
    complete_srch_str = glue::glue(
      "TS=(({ebv_srch_str}) AND ({driver_srch_str}) AND (que*bec OR canada OR montr*al or Saint-Lawrence or Bas-Saint-Laurent or Saguenay or Lac-Saint-Jean  or Capitale-Nationale or Mauricie or Estrie or Outaouais or Abitibi-T*miscamingue or C*te-Nord or Nord-du-Qu*bec or Gasp*sie–*les-de-la-Madeleine or Chaudi*re-Appalaches or Laval or Lanaudi*re or Laurentides or Mont*r*gie or Centre-du-Qu*bec))"
    )
  )


fs::dir_create(here::here("P3_moteurs_changement/out/jaureguiberry2022"))
readr::write_csv(
  complete_srch_df,
  here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/complete_search_str.csv"
  )
)
