df = readr::read_csv("Chapitres/Ne500/atlantic-bird-colonies.csv")

library(leaflet)
library(mapview)

m = leaflet() |> addTiles()
m = m |> setView(-65, 55, zoom = 4)
m = m |> addMarkers(lng = ~COL_LONDEC, lat = ~COL_LATDEC, data=df)

mapshot(m, file="Chapitres/Ne500/bird_data.png")