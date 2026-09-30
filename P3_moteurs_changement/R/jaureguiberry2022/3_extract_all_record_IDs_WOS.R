# keyring::key_set("clarivate-WOS-extended")
WOS_KEY <- keyring::key_get("clarivate-WOS-extended")

extract_record_identifiers_from_json <- function(rec_page) {
  purrr::map(
    rec_page,
    \(rec) {
      rec |>
        purrr::pluck(
          "dynamic_data",
          "cluster_related",
          "identifiers"
        ) |>
        # Account for different nesting levels of 1 vs multiple elements
        purrr::map(
          \(x) {
            if (purrr::pluck_exists(x, "type")) {
              return(list(x))
            }
            x
          }
        ) |>
        purrr::pluck("identifier") |>
        purrr::keep(\(id) {
          id$type == "doi"
        }) |>
        purrr::map(\(id) {
          tibble::tibble_row(doi = id$value)
        }) |>
        dplyr::bind_cols(
          tibble::tibble_row(
            uid = purrr::pluck(rec, "UID")
          )
        )
    }
  ) |>
    dplyr::bind_rows() |>
    dplyr::rename_with(~ gsub("identifier$", "", .x, fixed = TRUE))
}

get_records_from_page <- function(
  database,
  complete_srch_str, # query
  records_found,
  page,
  rec_per_page
) {
  Sys.sleep(0.5) # Don't flip through pages too quickly
  rec_page <- try({
    httr2::request(glue::glue(
      "https://wos-api.clarivate.com/api/wos/"
    )) |>
      httr2::req_url_query(
        usrQuery = complete_srch_str,
        optionView = "SR",
        databaseId = database,
        count = rec_per_page,
        firstRecord = page * rec_per_page - rec_per_page + 1
      ) |>
      httr2::req_headers(
        `X-ApiKey` = WOS_KEY,
        accept = "application/json"
      ) |>
      httr2::req_perform() |>
      httr2::resp_body_json() |>
      purrr::chuck("Data", "Records", "records", "REC")
  })
  if (inherits(rec_page, "try-error")) {
    # Note when, where and what errors happened
    browser()
    write(
      glue::glue(
        "{Sys.time()}: Following error occured on page: {page} of queryId: {queryId}. \n 
        {attr(rec_page,'condition') |> cli::ansi_strip()} \n"
      ),
      file = fs::path(root, "log.txt"),
      append = TRUE
    )
    return()
  }
  extract_record_identifiers_from_json(rec_page)
}


get_records_across_pages <- function(
  database,
  complete_srch_str,
  records_found,
  `EBV class`,
  driver1,
  driver2,
  Indicator,
  ...
) {
  rec_per_page = 100
  1:ceiling(records_found / rec_per_page) |>
    purrr::map(
      \(page) {
        get_records_from_page(
          database,
          complete_srch_str,
          records_found,
          page,
          rec_per_page
        )
      }
    ) |>
    dplyr::bind_rows() |>
    dplyr::mutate(
      `EBV class` = `EBV class`,
      driver1 = driver1,
      driver2 = driver2,
      Indicator = Indicator
    )
}

query_wos <- function(queries, database) {
  fs::dir_create(root)

  queries |>
    dplyr::filter(
      records_found > 0,
      database == database
    ) |>
    purrr::pmap(get_records_across_pages) |>
    dplyr::bind_rows()
}

root <- here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/search_results/"
)

queries <- readr::read_csv(here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/num_records_found.csv"
))

# ## TEST
# sample_queries = queries |>
#   dplyr::filter(records_found > 0) |>
#   dplyr::slice_sample(n = 5)
#
# search_results = query_wos(sample_queries, "WOS")

job::job({
  search_results = query_wos(queries, "WOS")
  search_results |>
    readr::write_csv(fs::path(root, "quebec.csv"))
})
