## You need ollama installed on your computer for this script to work
# Dowload at: https://ollama.com/download
# Launch ollama app in the terminal by running `ollama`

ollamar::test_connection() # Make sure you get a 200 OK response

# ollamar::pull("llama3.2:1b")

# ollamar::generate()

# Read input file
input_file <- here::here(
  "P3_moteurs_changement/out/jaureguiberry2022/search_results/unique_abstracts_from_doi.csv"
)
df <- readr::read_csv(input_file)

# prompt
system_prompt <- readr::read_file(
  file = here::here(
    "P3_moteurs_changement/R/jaureguiberry2022/first_pass_prompt_short.md"
  )
)

user_prompt <- "Title: {title} \nAbstract: {abstract}"

structured_output <- list(
  type = "object",
  properties = list(
    drivers = list(
      type = "array",
      items = list(type = "string"),
      description = "Classes of direct drivers of biodiversity loss identified in the study, if any.",
      enum = readr::read_csv(here::here(
        "P3_moteurs_changement/_data/jaureguiberry2022/Table_S2.csv"
      )) |>
        dplyr::pull(`Human-caused drivers`),
      uniqueItems = TRUE
    ),
    EBVs = list(
      type = "array",
      description = "List of EBV class or classes measured by the study, if any",
      items = list(type = "string"),
      uniqueItems = TRUE,
      enum = readr::read_csv(here::here(
        "P3_moteurs_changement/_data/jaureguiberry2022/EBV_general.csv"
      )) |>
        dplyr::pull(`EBV class`)
    ),
    decision = list(type = "string", enum = c("retain", "exclude")),
    reason = list(
      type = "string",
      description = "A brief 1-2 sentence explanation for the decision."
    )
  ),
  required = list("drivers", "EBVs", "decision", "reason")
)

prompt_llm <- function(doi, title, abstract, ...) {
  response <- ollamar::chat(
    model = "llama3.1",
    messages = list(
      list(role = "system", content = system_prompt),
      list(role = "user", content = glue::glue(user_prompt))
    ),
    format = structured_output,
    output = "jsonlist"
  )
}

sample_papers <- df |>
  tidyr::drop_na(doi) |>
  tidyr::drop_na(abstract) |>
  dplyr::sample_n(size = 10)

response <- sample_papers |>
  purrr::pmap(prompt_llm)

response |>
  # purrr::map(httr2::resp_body_json) |>
  # purrr::discard_at("context")
  jsonlite::write_json(here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/first_pass_filter.test.json"
  ))

## Extract required variable
response |>
  purrr::map2(sample_papers$doi, \(x, y) {
    # browser()
    paper = sample_papers |> dplyr::filter(doi == y)
    purrr::pluck(x, "message", "content") |>
      jsonlite::fromJSON() |>
      purrr::prepend(list(
        "doi" = y,
        title = dplyr::pull(paper, title),
        abstract = dplyr::pull(paper, abstract)
      ))
  }) |>
  jsonlite::write_json(here::here(
    "P3_moteurs_changement/out/jaureguiberry2022/first_pass_response.test.json"
  ))


beepr::beep()
