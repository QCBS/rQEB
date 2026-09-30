box::use(`2_MoteursChangement`/R/land_use_aafc[...])

## Calculate zonal stats (can take a while)

job::job({ 
  box::use(`2_MoteursChangement`/R/land_use_aafc[...])
  zonal_land_use = calc_zonal_land_uses() 
  })

summary_qc_zonal_land_use = summarise_qc_land_use(zonal_land_use, incl_all_qc=F)
summary_qc_zonal_and_summary_land_use = summarise_qc_land_use(zonal_land_use, incl_all_qc=T)


## Save summary

readr::write_csv(summary_qc_zonal_land_use, "2_MoteursChangement/Out/summary_qc_zonal_land_use.csv")
readr::write_csv(summary_qc_zonal_and_summary_land_use, "2_MoteursChangement/Out/summary_qc_zonal_and_summary_land_use.csv")

## For sud du Quebec

qc_sud_land_use = calc_qc_sud_land_uses() 
summary_qc_sud_land_use = summarise_qc_land_use(qc_sud_land_use, incl_all_qc=F) 

readr::write_csv(summary_qc_sud_land_use, "2_MoteursChangement/Out/summary_sud_qc_land_use.csv")
