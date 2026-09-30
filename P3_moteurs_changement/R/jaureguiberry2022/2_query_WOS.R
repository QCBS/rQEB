# keyring::key_set("clarivate-WOS-extended")
WOS_KEY <- keyring::key_get("clarivate-WOS-extended")

numb_recs_found <- function(q, databaseId = "WOK") {
  Sys.sleep(0.5)
  httr2::request("https://wos-api.clarivate.com/api/wos/") |>
    httr2::req_url_query(
      databaseId = databaseId,
      usrQuery = q,
      optionView = "SR",
      count = 1,
      firstRecord = 1
    ) |>
    httr2::req_headers(`X-ApiKey` = WOS_KEY, accept = "application/json") |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::keep_at("QueryResult")
}

job::job({
  query_df <- readr::read_csv(here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/complete_search_str.csv"
  )) |>
    tidyr::expand_grid(database = c("WOS", "WOK")) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      query_results = numb_recs_found(complete_srch_str, database),
      query_id = purrr::pluck(query_results, "QueryID"),
      records_found = purrr::pluck(query_results, "RecordsFound")
    ) |>
    dplyr::select(-query_results)
})

readr::write_csv(
  query_df,
  here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/num_records_found.csv"
  )
)

totals = query_df |>
  dplyr::group_by(database) |>
  dplyr::summarise(sum = sum(records_found)) |>
  tibble::deframe()

box::use(ggplot2[...])

ggplot(query_df, aes(y = records_found, x = `EBV class`, fill = database)) +
  geom_col(position = "dodge") +
  facet_grid(rows = vars(driver2), cols = vars(driver1)) +
  scale_y_log10() +
  ggtitle(glue::glue(
    "Total records found in WOK: {totals['WOK']}, and in WOS: {totals['WOS']}"
  )) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))


fs::dir_create(here::here("P3_moteurs_changement/Fig/jaureguiberry2022/"))

ggsave(here::here(
  "P3_moteurs_changement/Fig/jaureguiberry2022/num_records_found.pdf"
))
