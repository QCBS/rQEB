install.packages(c(
  "ollamar",
  "here",
  "dplyr",
  "readr",
  "purrr",
  "httr2",
  "tidyr",
  "glue",
  "tibble"
))

ollamar::test_connection()
ollamar::pull("nimble")

# ---- Input ---------------------------------------------------------------
input_file <- here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/search_results/unique_abstracts_from_doi.csv"
)
df <- readr::read_csv(input_file)

driver_classes <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/jaureguiberry2022/Table_S2.csv"
)) |>
  dplyr::pull(`Human-caused drivers`) |>
  unique()

ebv_classes <- readr::read_csv(here::here(
  "P3_moteurs_changement/_data/jaureguiberry2022/EBV_general.csv"
)) |>
  dplyr::pull(`EBV class`) |>
  unique()

# ---- Build the questions once ---------------------------------------------
# Question names are keys, so use indexed keys and map back to labels afterwards.
driver_keys <- sprintf("driver_%02d", seq_along(driver_classes))
ebv_keys <- sprintf("ebv_%02d", seq_along(ebv_classes))

noul_question <- function(instructions, label) {
  list(
    type = "noul",
    instructions = instructions,
    criteria = list(
      "false" = glue::glue("The study does not address: {label}"),
      "true" = glue::glue("The study addresses: {label}")
    )
  )
}

questions <- c(
  purrr::set_names(
    purrr::map(driver_classes, \(d) {
      noul_question(
        "Does this study assess the (relative) importance of the following class of direct driver of biodiversity change?",
        d
      )
    }),
    driver_keys
  ),
  purrr::set_names(
    purrr::map(ebv_classes, \(e) {
      noul_question(
        "Does this study assess the biodiversity response using the following ?",
        e
      )
    }),
    ebv_keys
  )
)

# ---- Query function --------------------------------------------------------
prompt_nimble <- function(doi, title, abstract, ...) {
  resp <- httr2::request("http://localhost:11434/v1/systemone") |>
    httr2::req_body_json(list(
      model = "nimble",
      state = paste0("Title: ", title, "\nAbstract: ", abstract),
      questions = questions
    )) |>
    httr2::req_timeout(1600) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
}

run_in_chunks <- function(papers, fn, out_dir, chunk_size = 10) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  # ---- What's already done? ----
  done_dois <- load_results(out_dir)$dois
  pending <- papers |>
    tidyr::drop_na(doi, abstract) |>
    dplyr::distinct(doi, .keep_all = TRUE) |>
    dplyr::filter(!doi %in% done_dois)

  message(sprintf("%d done, %d pending", length(done_dois), nrow(pending)))
  if (nrow(pending) == 0) {
    return(invisible(tibble::tibble(doi = character(), error = character())))
  }

  chunk_ids <- ceiling(seq_len(nrow(pending)) / chunk_size)
  chunks <- split(pending, chunk_ids)
  next_idx <- length(list.files(out_dir, pattern = "^chunk_.*\\.rds$")) + 1
  failures <- list()

  for (i in seq_along(chunks)) {
    chunk <- chunks[[i]]
    t0 <- Sys.time()

    results <- purrr::pmap(chunk, \(doi, title, abstract, ...) {
      tryCatch(
        list(doi = doi, response = fn(doi, title, abstract)),
        error = \(e) list(doi = doi, error = conditionMessage(e))
      )
    })

    ok <- purrr::keep(results, \(r) is.null(r$error))
    bad <- purrr::discard(results, \(r) is.null(r$error))
    failures <- c(failures, bad)

    # atomic save: write to temp, then rename
    file <- file.path(out_dir, sprintf("chunk_%04d.rds", next_idx))
    tmp <- paste0(file, ".tmp")
    saveRDS(ok, tmp)
    file.rename(tmp, file)
    next_idx <- next_idx + 1

    message(sprintf(
      "[%s] chunk %d/%d saved: %d ok, %d failed (%.1f min)",
      format(Sys.time(), "%H:%M:%S"),
      i,
      length(chunks),
      length(ok),
      length(bad),
      as.numeric(difftime(Sys.time(), t0, units = "mins"))
    ))
  }

  if (length(failures) > 0) {
    message(length(failures), " papers failed; rerun to retry them.")
  }
  invisible(purrr::map(failures, tibble::as_tibble) |> purrr::list_rbind())
}

# Reads every saved chunk back into one list
load_results <- function(out_dir) {
  files <- list.files(out_dir, pattern = "^chunk_.*\\.rds$", full.names = TRUE)
  results <- purrr::map(files, readRDS) |> purrr::list_flatten()
  list(
    response = purrr::map(results, "response"),
    dois = purrr::map_chr(results, "doi")
  )
}

# ---- Run -------------------------------------------------------------------

out_dir <- here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/first_pass_chunks"
)

# test_df <- df |>
#   tidyr::drop_na(doi, abstract) |>
#   dplyr::distinct(doi, .keep_all = TRUE) |>
#   dplyr::sample_n(10)

failed <- run_in_chunks(
  papers = df, # full dataset; the function drops NA doi/abstract
  fn = prompt_nimble, # must return the raw response
  out_dir = out_dir,
  chunk_size = 10
)

#--------Retain studies

retain_studies <- function(
  response,
  dois,
  threshold = 0.5,
  min_drivers = 2,
  min_ebvs = 1
) {
  stopifnot(length(response) == length(dois))

  summary <- purrr::map2(response, dois, \(r, doi) {
    p <- purrr::map_dbl(r$answers, \(x) x$noul %||% NA_real_)
    tibble::tibble(
      doi = doi,
      n_drivers = sum(
        p[startsWith(names(p), "driver_")] > threshold,
        na.rm = TRUE
      ),
      n_ebvs = sum(p[startsWith(names(p), "ebv_")] > threshold, na.rm = TRUE)
    )
  }) |>
    purrr::list_rbind() |>
    dplyr::mutate(retain = n_drivers >= min_drivers & n_ebvs >= min_ebvs)

  list(
    dois = summary$doi[summary$retain],
    summary = summary
  )
}

res <- load_results(out_dir)
retained <- retain_studies(res$response, res$dois)
retained$dois
retained$summary

retained$dois |>
  tibble::as_tibble_col("doi") |>
  readr::write_csv(here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/first_pass_response.test_retained_dois.csv"
  ))
