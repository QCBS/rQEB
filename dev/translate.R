devtools::install_github("ropensci-review-tools/babeldown")
# keyring::key_set("deepl", prompt = "API key:")
Sys.setenv(DEEPL_API_KEY = keyring::key_get("deepl"))

## Scoping doc

babeldown::deepl_translate_quarto(
  ".",
  "Scoping/Scoping.qmd",
  source_lang = "FR",
  target_lang = "EN-US",
  render = F
)

## Homepage
# babeldown::deepl_translate_quarto(".",
#                                   "index.qmd",
#                                   source_lang="FR",
#                                   target_lang="EN-US", render=F, force=T)

babeldown::deepl_update(
  "index.qmd",
  "index.en.qmd",
  source_lang = "FR",
  target_lang = "EN-US"
)


## TDM

babeldown::deepl_translate_quarto(
  ".",
  "Scoping/TDM.qmd",
  source_lang = "FR",
  target_lang = "EN-US",
  render = F
)

babeldown::deepl_update(
  "Scoping/TDM.qmd",
  "Scoping/TDM.en.qmd",
  source_lang = "FR",
  target_lang = "EN-US"
)


## Contrib guide

babeldown::deepl_translate_quarto(
  ".",
  "CONTRIBUTE.qmd",
  source_lang = "FR",
  target_lang = "EN-US",
  render = F
)


babeldown::deepl_update(
  "CONTRIBUTE.qmd",
  "CONTRIBUTE.en.qmd",
  source_lang = "FR",
  target_lang = "EN-US"
)
