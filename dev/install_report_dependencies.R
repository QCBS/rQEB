## This files finds and installs all R package dependencies used in the report
# It runs automatically as part of a GitHub action workflow

if (!require(pak)) {
  install.packages("pak")
}
cache.dir <- "~/work/_temp/Library"
dir.create(cache.dir, recursive = TRUE)

pak::pkg_install(
  c("rlang", "yaml", "renv", "here", "ekatko1/babelquarto"),
  lib = cache.dir,
  upgrade = FALSE
)

book_yaml <- yaml::yaml.load_file(input = "_quarto-web-book.yml")

## Discover only dependencies required for building the report, not all the analyses
packages <- c()
find_deps <- function(qmd) {
  renv::dependencies(qmd)$Package
}

get_chaps <- function(book_yaml) {
  x = unlist(book_yaml$book); 
  x[grepl("*.qmd", x)]
}

for (chap in get_chaps(book_yaml)) {
  packages <- c(packages, find_deps(chap))
}

# Get all dependencies from root modules directory
packages <- c(packages, find_deps("R"))

## Install and create lockfile (for hash)
c(c("rmarkdown", "knitr"), packages) |>
  unique() |>
  print() |>
  pak::lockfile_create(lib = cache.dir)

pak::lockfile_install(lib = cache.dir)

# print(paste('# List of packages to be installed:', packages))
# install.packages(packages)
