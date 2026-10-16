out_dir <- here::here("P3_moteurs_changement/out/jaureguiberry2022")

df <- readr::read_csv(
  fs::path(out_dir, "search_results/quebec.csv")
)

remotes::install_github("ropensci/openalexR")

df |> summary()

box::use(dplyr[select, across, where, mutate, filter])

unique_id_df <- df |>
  select(where(\(x) {
    !all(is.na(x))
  })) |>
  filter(!is.na(`doi...7`)) |>
  mutate(doi = dplyr::coalesce(doi...1, doi...7, doi...8, doi...14)) |>
  select(doi, !starts_with("doi")) |>
  dplyr::distinct(doi, uid) #|>
# mutate(doi.uid = dplyr::coalesce(doi, uid) )

# Check Intersection with QCBS-authored papers in Quebec
# quebec_studies <- readr::read_csv(here::here(
#   "P3_moteurs_changement/_data/QCBS_quebec_studies.csv"
# )) |>
#   tidyr::pivot_longer(cols=dplyr::everything(), names_to = "classification", values_to = "doi") |>
#   tidyr::drop_na(doi) |>
#   dplyr::distinct()
#
# retained_dois = dplyr::inner_join(unique_id_df |> tidyr::drop_na(doi), quebec_studies, by="doi")
# Result: ~2%

## Get titles and abstracts from dois
# keyring::key_set("open-alex")
openalexR.apikey <- keyring::key_get("open-alex")

unique_dois <- unique_id_df |> tidyr::drop_na(doi) |> dplyr::pull(doi)
test_dois <- sample(unique_dois, 5)

# works_from_dois <- openalexR::oa_fetch(entity = "works", doi = unique_dois)
# readr::write_csv(works_from_dois, here::here("P3_moteurs_changement/out/jaureguiberry2022/search_results/OpenAlex_unique_abstracts_from_doi.csv"))
works_from_dois <- readr::read_csv(fs::path(
  out_dir,
  "/search_results/OpenAlex_unique_abstracts_from_doi.csv"
))

# Only about half of the dois could be found using OpenAlex
# Get the other half from clarivate using UID
unique_id_df2 <- unique_id_df |>
  dplyr::mutate(
    doi_http_lower = paste0("https://doi.org/", doi) |> tolower()
  ) |>
  dplyr::anti_join(
    works_from_dois |> mutate(doi_http_lower = doi |> tolower()),
    by = "doi_http_lower"
  )


# retreive by uid
WOS_KEY <- keyring::key_get("clarivate-WOS-extended")

get_records <- function(uid, ...) {
  Sys.sleep(0.5)
  try({
    out <- httr2::request(glue::glue(
      "https://wos-api.clarivate.com/api/wos/id/{uid}"
    )) |>
      httr2::req_url_query(
        databaseId = "WOS",
        optionView = "FR",
      ) |>
      httr2::req_headers(
        `X-ApiKey` = WOS_KEY,
        accept = "application/json"
      ) |>
      httr2::req_perform() |>
      httr2::resp_body_json()
  })
  if (inherits(out, "try-error")) {
    write(
      glue::glue(
        "{Sys.time()}: Following error occured on page: {page} of queryId: {queryId}. \n 
        {attr(rec_page,'condition') |> cli::ansi_strip()} \n"
      ),
      file = here::here(fs::path(
        "P3_moteurs_changement/out/jaureguiberry2022/search_results/",
        "log.txt"
      )),
      append = TRUE
    )

    return()
  }
  out
}

chunk_records <- function(df, chunk_size = 100) {
  df |>
    dplyr::mutate(chunk_id = ceiling(1:nrow(df) / chunk_size)) |>
    dplyr::group_by(chunk_id) |>
    dplyr::group_split()
}

save_chunk_results <- function(chunk) {
  f = fs::dir(
    out_dir,
    "/search_results/WOS_FullRecord/"
  )
  fs::dir_create(f)
  chunk_id <- unique(chunk$chunk_id) |> stringr::str_pad(width = 3, pad = 0)
  chunk_json <- purrr::pmap(chunk, get_records)
  jsonlite::write_json(
    chunk_json,
    fs::path(f, glue::glue("chunk-{chunk_id}.json"))
  )
}

# TEST
# unique_id_df2 |>
#   dplyr::slice_sample(n = 10) |> #
#   chunk_records(chunk_size = 3) |>
#   purrr::map(save_chunk_results)

job::job({
  unique_id_df2 |>
    chunk_records() |>
    purrr::map(save_chunk_results)
})

#### Combine json chunks and extract
str(works_from_dois)

files <- list.files(
  fs::path(out_dir, "search_results/WOS_FullRecord"),
  pattern = "^chunk-\\d+\\.json$",
  full.names = TRUE
)

# Wrap a lone object in a list so we can always iterate
as_list_of <- function(x) {
  if (is.null(x)) {
    return(list())
  }
  if (!is.null(names(x))) list(x) else x
}

# Every scalar is wrapped in a length-1 array: unwrap to a plain string
scalar <- function(x) {
  x <- unlist(x, use.names = FALSE)
  if (length(x) == 0) NA_character_ else as.character(x[[1]])
}

get_doi <- function(rec) {
  ids <- as_list_of(rec$dynamic_data$cluster_related$identifiers$identifier)
  types <- purrr::map_chr(ids, \(i) scalar(i$type))
  idx <- match("doi", types)
  if (is.na(idx)) {
    idx <- match("xref_doi", types)
  } # fall back to xref_doi
  if (is.na(idx)) NA_character_ else scalar(ids[[idx]]$value)
}

get_title <- function(rec) {
  tt <- as_list_of(rec$static_data$summary$titles$title)
  types <- purrr::map_chr(tt, \(i) scalar(i$type))
  idx <- match("item", types)
  if (is.na(idx)) NA_character_ else scalar(tt[[idx]]$content)
}

get_abstract <- function(rec) {
  p <- rec$static_data$fullrecord_metadata$abstracts$abstract$abstract_text$p
  if (is.null(p)) NA_character_ else paste(unlist(p), collapse = " ")
}

read_chunk <- function(f) {
  queries <- as_list_of(jsonlite::read_json(f, simplifyVector = FALSE))

  # Empty queries have records = [""], so $REC is NULL and they drop out
  recs <- purrr::map(queries, \(q) as_list_of(q$Data$Records$records$REC)) |>
    purrr::list_flatten()

  tibble::tibble(
    doi = purrr::map_chr(recs, get_doi),
    title = purrr::map_chr(recs, get_title),
    abstract = purrr::map_chr(recs, get_abstract)
  )
}

wos <- purrr::map(files, read_chunk) |>
  purrr::list_rbind() |>
  dplyr::distinct()


## Combine OpenAlex and WOS searches
oa_wos <- dplyr::bind_rows(
  wos,
  works_from_dois |> dplyr::select(doi, title, abstract)
)

arrow::write_parquet(oa_wos, fs::path(out_dir, "4_abstracts.parquet"))
readr::write_csv(oa_wos, fs::path(out_dir, "4_abstracts.csv"))
