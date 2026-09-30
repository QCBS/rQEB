box::use(osfr[...])

data_folder = here::here("P2_nature/especes_menaces/_data")

fs::dir_create(data_folder)

osf_retrieve_node("https://osf.io/e4a58") |>
  osf_ls_files() |>
  dplyr::filter(name == "CAN-SAR_database.csv") |>
  osf_download(path = data_folder)

df = readr::read_csv(file = fs::path(data_folder, "/CAN-SAR_database.csv")) #colnames()


nrow(df)

df_qc = df |>
  dplyr::rowwise() |>
  dplyr::filter(stringr::str_detect(ranges, "QC")) #

df_qc |>
  nrow()

View(df_qc)


df |> dplyr::filter(is.na(ranges))
df |> dplyr::filter(ranges == "NE")


osf_retrieve_node("https://osf.io/e4a58") |>
  osf_ls_files() |>
  dplyr::filter(name == "CAN-SAR_data_dictionary.xlsx") |>
  osf_download(data_folder)

box::use(dplyr[if_all, matches])
df_qc |>
  dplyr::filter(
    if_all(
      matches("^X[0-9][.][0-9]_iucn_impact$"),
      ~ is.na(.) | . < 0
    )
  ) |>
  nrow()


df_qc_with_data = df_qc |>
  dplyr::filter(
    if_any(
      matches("^X[0-9][.][0-9]_iucn_impact$"),
      ~ !is.na(.) | . >= 0
    )
  )

df_qc_with_data |> dplyr::pull(species)
