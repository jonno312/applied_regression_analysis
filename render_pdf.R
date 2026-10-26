# Render the entire textbook as a single PDF.
#
# The table of contents comes from the "Contents" section of README.md, so
# a chapter is included in the PDF if and only if it's listed there.
# Run this script from the project root, e.g., `source("render_pdf.R")`.

library(quarto)

# Settings
include_solutions <- TRUE
if(include_solutions) {
  output_file <- "applied_regression_analysis_wsolutions.pdf"
} else {
  output_file <- "applied_regression_analysis.pdf"
}
appendix_dir <- "A_problems_with_coding"

# Find the Quarto command-line tool, falling back on the copy bundled with
# RStudio if Quarto isn't on the PATH
find_quarto <- function() {
  if (!is.null(quarto_path())) {
    return(invisible(TRUE))
  }
  candidates <- c(
    Sys.getenv("RSTUDIO_QUARTO"),
    "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (length(candidates) == 0) {
    stop("Couldn't find Quarto. Install it from https://quarto.org or run ",
         "this script from within RStudio.")
  }
  Sys.setenv(QUARTO_PATH = candidates[1])
  invisible(TRUE)
}

# Make sure some version of LaTeX is installed
check_latex <- function() {
  has_tinytex <- requireNamespace("tinytex", quietly = TRUE) &&
    tinytex::is_tinytex()
  if (!has_tinytex && !nzchar(Sys.which("pdflatex"))) {
    stop("Couldn't find LaTeX. Install it by running:\n",
         "  install.packages(\"tinytex\")\n",
         "  tinytex::install_tinytex()")
  }
}

# Parse the "Contents" section of the README into a list of parts, each of
# which has a title and a vector of chapter files
parse_readme_contents <- function(readme = "README.md") {
  lines <- readLines(readme, warn = FALSE)
  start <- grep("^## Contents", lines)
  end <- grep("^## ", lines)
  end <- end[end > start][1]
  lines <- lines[(start + 1):(end - 1)]

  parts <- list()
  for (line in lines) {
    if (grepl("^[0-9]+\\. ", line)) {
      title <- sub("^[0-9]+\\. +", "", line)
      parts[[length(parts) + 1]] <- list(part = title, chapters = character(0))
    } else if (grepl("\\]\\([^)]+\\.qmd\\)", line) && length(parts) > 0) {
      file <- sub(".*\\]\\(([^)]+\\.qmd)\\).*", "\\1", line)
      n <- length(parts)
      parts[[n]]$chapters <- c(parts[[n]]$chapters, file)
    }
  }

  # Fail loudly rather than silently dropping chapters
  chapters <- unlist(lapply(parts, `[[`, "chapters"))
  if (length(parts) == 0 || length(chapters) == 0) {
    stop("Couldn't find any parts or chapters in the Contents section of ",
         readme, ".")
  }
  missing <- chapters[!file.exists(chapters)]
  if (length(missing) > 0) {
    stop("These chapters are listed in ", readme, " but don't exist:\n  ",
         paste(missing, collapse = "\n  "))
  }
  parts
}

# Return the local (non-URL) data files that a Quarto document reads
local_data_files <- function(file) {
  text <- paste(readLines(file, warn = FALSE), collapse = "\n")
  calls <- regmatches(
    text,
    gregexpr("read(_xlsx?|_excel|\\.csv|_csv)\\([^)]*\\)", text)
  )[[1]]
  paths <- sub("^[^\"]*\"([^\"]+)\".*$", "\\1", calls)
  paths <- paths[!grepl("^https?://", paths)]
  file.path(dirname(file), paths)
}

# List the appendix files to include: each problem set followed by its
# solutions, keeping only files whose data are present
select_appendix_files <- function() {
  files <- sort(list.files(appendix_dir, pattern = "\\.qmd$",
                           full.names = TRUE))
  problems <- files[!grepl("_solutions\\.qmd$", files)]
  files <- unlist(lapply(problems, function(f) {
    solutions <- sub("\\.qmd$", "_solutions.qmd", f)
    c(f, if (include_solutions && file.exists(solutions)) solutions)
  }))

  keep <- vapply(files, function(f) {
    missing <- local_data_files(f)
    missing <- missing[!file.exists(missing)]
    if (length(missing) > 0) {
      message("Skipping ", f, " (missing ",
              paste(basename(missing), collapse = ", "), ")")
    }
    length(missing) == 0
  }, logical(1))
  unname(files[keep])
}

# Make sure every package used in the R chunks is installed
check_packages <- function(files) {
  code <- unlist(lapply(files, function(f) {
    lines <- readLines(f, warn = FALSE)
    fences <- grepl("^```", lines)
    in_chunk <- cumsum(fences) %% 2 == 1 & !fences
    lines[in_chunk]
  }))
  code <- sub("#.*$", "", code)
  pkgs <- c(
    unlist(regmatches(code, gregexpr("(?<=library\\()[A-Za-z0-9.]+", code,
                                     perl = TRUE))),
    unlist(regmatches(code, gregexpr("[A-Za-z][A-Za-z0-9.]*(?=::)", code,
                                     perl = TRUE)))
  )
  pkgs <- sort(unique(pkgs))
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop("Please install the following packages first:\n  install.packages(",
         deparse(missing, width.cutoff = 500), ")")
  }
}

# Write the front page of the book, using the README's description and
# license sections
write_index <- function(path) {
  lines <- readLines("README.md", warn = FALSE)
  section <- function(name) {
    start <- grep(paste0("^## ", name), lines)
    end <- grep("^## ", lines)
    end <- c(end[end > start], length(lines) + 1)[1]
    lines[(start + 1):(end - 1)]
  }
  writeLines(c("# Preface {.unnumbered}", section("Description"),
               "## License {.unnumbered}", section("License")),
             file.path(path, "index.qmd"))
}

# Write a Lua filter that removes the "Solution" callouts (Quarto turns
# callout divs into its own Callout elements before user filters run)
write_solution_filter <- function(path) {
  writeLines(c(
    "function Callout(el)",
    "  if el.type == 'tip' and",
    "     pandoc.utils.stringify(el.title) == 'Solution' then",
    "    return {}",
    "  end",
    "end"
  ), file.path(path, "remove-solutions.lua"))
}

render_pdf <- function() {
  # Check prerequisites
  find_quarto()
  check_latex()
  parts <- parse_readme_contents()
  appendices <- select_appendix_files()
  chapters <- c(unlist(lapply(parts, `[[`, "chapters")), appendices)
  check_packages(chapters)

  # Copy the textbook into a temporary directory so that nothing in the
  # project (other than the final PDF) is touched
  build_dir <- tempfile("textbook_pdf_")
  dir.create(build_dir)
  on.exit(unlink(build_dir, recursive = TRUE), add = TRUE)
  for (d in unique(dirname(chapters))) {
    file.copy(d, build_dir, recursive = TRUE)
  }
  write_index(build_dir)

  # Write the book's configuration
  config <- list(
    project = list(type = "book"),
    book = list(
      title = sub("^# ", "", readLines("README.md", n = 1)),
      chapters = c(list("index.qmd"), lapply(parts, function(p) {
        list(part = p$part, chapters = as.list(p$chapters))
      }))
    ),
    format = list(pdf = list(
      documentclass = "scrreprt",
      toc = TRUE,
      `toc-depth` = 1,
      `number-sections` = TRUE
    )),
    execute = list(warning = FALSE, message = FALSE)
  )
  if (length(appendices) > 0) {
    config$book$appendices <- as.list(appendices)
  }
  if (!include_solutions) {
    write_solution_filter(build_dir)
    config$filters <- list("remove-solutions.lua")
  }
  yaml::write_yaml(config, file.path(build_dir, "_quarto.yml"),
                   handlers = list(logical = yaml::verbatim_logical))

  # Render the book and copy the PDF back into the project
  message("Rendering ", length(chapters), " chapters to PDF ",
          "(this will take several minutes)...")
  quarto_render(build_dir, output_format = "pdf", as_job = FALSE)
  pdf <- list.files(file.path(build_dir, "_book"), pattern = "\\.pdf$",
                    full.names = TRUE)
  file.copy(pdf[1], output_file, overwrite = TRUE)
  message("Done: ", normalizePath(output_file))
  invisible(output_file)
}

render_pdf()
