webshot2::webshot("Scoping/Fig/_ethic-diagram.html", file="Scoping/Fig/fig-ethic.png", 
                  vwidth = 780, vheight=700)


quarto::quarto_render(input="Scoping/Fig/_ethic-diagram.en.qmd")
webshot2::webshot("Scoping/Fig/_ethic-diagram.en.html", file="Scoping/Fig/fig-ethic.en.png", 
                  vwidth = 780, vheight=700)
