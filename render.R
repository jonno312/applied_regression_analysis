# Run this script to render all quarto documents in this folder
# and every sub-folder.

library(quarto)

render_all_quarto <- function(path = ".") {
  # Find all .qmd files recursively in the specified path
  qmd_files <- list.files(
    path = path,
    pattern = "\\.qmd$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  if (length(qmd_files) == 0) {
    message("No .qmd files found in: ", path)
    return(invisible(character(0)))
  }
  
  # Render each file
  for (f in qmd_files) {
    message("Rendering: ", f)
    quarto_render(input = f)
  }
  
  invisible(qmd_files)
}

render_all_quarto()
