## Customized babelquarto install
# pak::pak("ekatko1/babelquarto")
# remotes::install_github("ekatko1/babelquarto", force=T)
babelquarto::render_book(".", profile = "web-book")
