box::use(./R/land_use_aafc[get_aafc_metadata])

qc = readr::read_csv("2_MoteursChangement/Out/summary_qc_zonal_and_summary_land_use.csv") |>
  dplyr::filter(qc_region == "Québec (province)")

qc_sud = readr::read_csv("2_MoteursChangement/Out/summary_sud_qc_land_use.csv")

#' Extract brakdown for urban land types across land use summary dataframe
#' 
#' @param df Summary dataframe (ex: produced by summarise_qc_land_use()) 
extract_urban_use_breakdown <- function(df, yr=2020) {
  data = df |> 
    dplyr::filter(year == yr) |> 
    tidyr::pivot_longer(cols=starts_with("frac"), 
                        names_pattern = "frac_(\\d{2})", 
                        names_to="Code", 
                        values_to = "frac") |> 
    dplyr::mutate(Code = as.numeric(Code)) |>
    dplyr::left_join(get_aafc_metadata() ) |>
    dplyr::filter(Code %in% get_aafc_classes("Settlement", summary_col_name=F)) |>
    tidyr::replace_na( list(frac=0) ) |>
    dplyr::mutate(sCode = Code %% 10, 
                  perc = frac*100) 
  
  new_data = data |> 
    dplyr::filter(Code > 40) |>
    dplyr::rename(perc.new = perc) |>
    dplyr::select(sCode, perc.new)
    
  data |>
    dplyr::summarise(
      perc.total = sum(perc),
      .by = c(sCode)) |>
    dplyr::bind_cols(
      data |> 
        dplyr::filter(Code < 50) |> 
        dplyr::select("Classes d\u0092utilisation", "Landuse Class")) |>
    dplyr::rename(Classe = "Classes d\u0092utilisation") |>
    dplyr::left_join(new_data) |>
    dplyr::mutate(Classe = forcats::fct_reorder(Classe, perc.total)) |>
    dplyr::mutate(
      `Landuse Class` = 
        forcats::fct_reorder(`Landuse Class`, perc.total)
    ) |>
    tidyr::pivot_longer(cols = c(perc.total, perc.new), names_to = "Type")
}

box::use(ggplot2[...], R/get_fig_styles[...])

plot_aafc_urban_land_uses <- function(lang = c("fr", "en"), yr=2020) {
  lang = match.arg(lang)
  if(lang == "en") {
    qc_text =  "Quebec (province)"
    qc_sud_text = "Southern Québec (49th parallel)"
    land_use_perc_text = "Land use in 2020 (%)"
    land_use_class_text = "Urban land use classes"
    total_perc_text = glue::glue("Total in {yr}")
    new_perc_text = glue::glue("New since {yr-10}")
    qc_reg_text = "Region:"
    y_var = "Landuse Class"
  } else {
    qc_text =  "Québec (province)"
    qc_sud_text = "Sud du Québec (49e parallèle)"
    land_use_perc_text = "Utilisation des terres en 2020 (%)"
    land_use_class_text = "Classes d'utilisation urbaines des terres"
    qc_reg_text = "Région:"
    total_perc_text = glue::glue("Total en {yr}")
    new_perc_text = glue::glue("Nouveau depuis {yr-10}")
    
    y_var = "Classe"
  }
  data = dplyr::bind_rows(
    qc |> extract_urban_use_breakdown(yr) |> dplyr::mutate( region = qc_text),
    qc_sud |> extract_urban_use_breakdown(yr) |> dplyr::mutate( region = qc_sud_text)
  ) |>
    dplyr::rename(
      !! sym(land_use_perc_text) := value ,
      # !! sym(land_use_class_text) := !! sym(y_var), 
      !! sym(qc_reg_text) := region,
    ) |> 
    dplyr::mutate(Type = forcats::fct_recode( 
      Type,
      "{total_perc_text}" := "perc.total", 
      "{new_perc_text}" := "perc.new")) |> 
    dplyr::select(Type,
                  !! sym(y_var), 
                  !! sym(land_use_perc_text), 
                  !! sym(qc_reg_text)) 
  data |>
    tidyr::pivot_wider(names_from = !! sym(qc_reg_text), 
                       values_from = !! sym(land_use_perc_text)) |>
    readr::write_csv(glue::glue("2_MoteursChangement/Out/table_qc_urban_breakdown.{lang}.csv"))

  data |> 
    dplyr::filter(Type==total_perc_text) |>
    ggplot2::ggplot(
      aes(y=.data[[y_var]], 
          x=.data[[land_use_perc_text]],
          # color = Type, 
          fill  = .data[[qc_reg_text]])) + 
    geom_col(position="dodge", orientation="y") +
    scale_y_discrete(name=land_use_class_text, labels=scales::label_wrap(22)) +
    scale_fill_viridis_d(name=qc_reg_text, end=0.8, begin=0.2) +
    style_plot() + 
    layer(geom="col", stat="identity", 
          position= "dodge",
          mapping = aes(color = Type),
          params = list(
            linetype="dashed", 
            alpha=0),
          data = data |> 
            dplyr::filter(Type==new_perc_text)) +
    guides(colour = guide_legend(order = 1, title=""), 
           fill="legend") +
    theme(legend.position = "bottom", 
          legend.box.margin = margin(l = -0.25, unit = "npc")) 
}
plot_aafc_urban_land_uses("fr", yr=2015)
ggsave("2_MoteursChangement/Fig/urban_land_use_breakdown.png", width=7, height = 5)

plot_aafc_urban_land_uses("en", yr=2015)
ggsave("2_MoteursChangement/Fig/urban_land_use_breakdown.en.png", width=7, height = 5)

