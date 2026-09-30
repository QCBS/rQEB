library(DiagrammeR)
library(glue)
library(dplyr)

nodes <- data.frame(id = c("A","B","C","D","E","F","G"))

nodes$label <- c(
  "Suivi et\nobservation",
  "Indicateurs",
  "Statut et\ntendances",
  "Attribution\ndes causes",
  "Scénarios\nprospectifs",
  "Orientations\npour les\npolitiques\npubliques",
  "Gestion\nadaptative"
)


nodes$label_en <- c(
  "Monitoring and\nobservation",
  "Indicators",
  "Status and\ntrends",
  "Attribution\nof drivers",
  "Exploratory\nscenarios",
  "Guidance\nfor public\npolicies",
  "Adaptive\nmanagement"
)

nodes$shape = c('doublecircle', rep('circle', 6))

nodes = nodes |>
  mutate(angle = 2*pi*(9:3/7),
         x = 4*cos(angle) |> round(2), 
         y = 4*sin(angle) |> round(2))

create_fig <- function(lang = "fr"){
  if(lang == "en") labels = nodes$label_en else labels = nodes$label
  node_lines <- glue(
    '{nodes$id} [label="{labels}", pos="{nodes$x},{nodes$y}!", shape={nodes$shape}];'
  )
  
  dot <- glue('
digraph BiodiversityCycle {{

    layout=neato;
    graph [overlap=false];
    splines=true

    node [
        shape=circle,
        fixedsize=true,
        width=2.6,
        height=2.6,
        fontsize=26,
        fontname="Helvetica",
        style="filled",
        fillcolor="#E8F2F8"
    ];

edge [penwidth=1.5, arrowsize=1.2];

{paste(node_lines, collapse="\n")}

A -> B -> C -> D -> E -> F -> G -> A;

}}
')
  
  g = grViz(dot)
  dir.create('Scoping/Fig')
  library(vtree)
  if(lang=="en") {
    grVizToPNG(g, filename='Scoping/Fig/fig-work-cycle-en.png')
  } else {
    grVizToPNG(g, filename='Scoping/Fig/fig-work-cycle.png')
  }
}

create_fig("fr")
create_fig("en")