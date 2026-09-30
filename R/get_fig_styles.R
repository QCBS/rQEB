#' Default patchwork options 
#' @export
style_patchwork = function() {
  list(
  patchwork::plot_layout(guides="collect"), 
  patchwork::plot_annotation(tag_level = 'a', tag_suffix = ")"))
}

#' Default styling options for ggplots 
#' @export
style_plot = function() {
  list(
  ggplot2::theme_classic()
  )
}