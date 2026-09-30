search_result_incomplete <- readr::read_csv(here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/search_results_incomplete.csv"
)) |> 
  dplyr::select(dplyr::starts_with("doi")) |> 
  dplyr::rename("doi" = "doi...4") |>
  dplyr::select(doi) |>
  dplyr::distinct() |>
  tidyr::drop_na()
  
search_result_incomplete
dplyr::mutate()

quebec_studies <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/QCBS_quebec_studies.csv"
)) |> 
  tidyr::pivot_longer(cols=dplyr::everything(), names_to = "classification", values_to = "doi") |>
  tidyr::drop_na(doi)


retained_dois = dplyr::inner_join(search_result_incomplete, quebec_studies, by="doi") 

retained_dois
# , by = c("doi...4"="doi"))
