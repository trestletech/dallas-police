shinyUI <- function(ui, output){
  textConn <- textConnection(NULL, "w")
  shiny:::renderPage(ui, textConn, FALSE)
  html <- paste(textConnectionValue(textConn), collapse = "\n")
  writeLines(html, file("www/index.html"))
  close(textConn)
}
