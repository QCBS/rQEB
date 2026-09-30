box::use(./R/land_use_aafc[...])

# Read data
summary_qc_zonal_land_use = readr::read_csv("2_MoteursChangement/Out/summary_qc_zonal_land_use.csv")
summary_qc_zonal_and_summary_land_use = readr::read_csv("2_MoteursChangement/Out/summary_qc_zonal_and_summary_land_use.csv")

## Plot

save_urban_land_use_over_time_figures(summary_qc_zonal_land_use, 9, 5)
save_agri_land_use_over_time_figures(summary_qc_zonal_land_use, 7, 5)

