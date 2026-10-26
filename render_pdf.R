# Render the entire textbook as a single PDF, or as a folder of HTML pages.
#
# The table of contents comes from the "Contents" section of README.md, so
# a chapter is included in the book if and only if it's listed there.
# Run this script from the project root, e.g., `source("render_pdf.R")`.
#
# The GitHub Action in .github/workflows/publish.yml also uses this script to
# build the website and PDFs.

# Settings
book_format <- "pdf"  # or "html"
include_solutions <- TRUE

# The GitHub Action overrides the settings above with environment variables
book_format <- Sys.getenv("BOOK_FORMAT", book_format)
include_solutions <- as.logical(Sys.getenv("INCLUDE_SOLUTIONS",
                                           include_solutions))
pdf_links <- as.logical(Sys.getenv("BOOK_PDF_LINKS", "FALSE"))
output_file <- "applied_regression_analysis"
if(include_solutions) {
  output_file <- paste0(output_file, "_wsolutions")
}
if(book_format == "pdf") {
  output_file <- paste0(output_file, ".pdf")
} else {
  output_file <- paste0(output_file, "_html")
}
appendix_dir <- "A_problems_with_coding"

# Find the Quarto command-line tool, falling back on the copy bundled with
# RStudio if Quarto isn't on the PATH
find_quarto <- function() {
  if (!is.null(quarto::quarto_path())) {
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

# List the (non-base) packages used in the R chunks
list_packages <- function(files) {
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
  setdiff(pkgs, rownames(installed.packages(priority = "base")))
}

# Make sure every package used in the R chunks is installed
check_packages <- function(files) {
  pkgs <- list_packages(files)
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop("Please install the following packages first:\n  install.packages(",
         deparse(missing, width.cutoff = 500), ")")
  }
}

# Write the front page of the book, using the README's description and
# license sections (plus links to the PDFs, for the website)
write_index <- function(path) {
  lines <- readLines("README.md", warn = FALSE)
  section <- function(name) {
    start <- grep(paste0("^## ", name), lines)
    end <- grep("^## ", lines)
    end <- c(end[end > start], length(lines) + 1)[1]
    lines[(start + 1):(end - 1)]
  }
  downloads <- if (pdf_links) {
    c("## Download {.unnumbered}", "",
      "- [PDF without solutions](applied_regression_analysis.pdf)",
      "- [PDF with solutions](applied_regression_analysis_wsolutions.pdf)",
      "")
  }
  writeLines(c("# Preface {.unnumbered}", section("Description"), downloads,
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

render_book <- function() {
  # Check prerequisites
  find_quarto()
  if (book_format == "pdf") {
    check_latex()
  }
  parts <- parse_readme_contents()
  appendices <- select_appendix_files()
  chapters <- c(unlist(lapply(parts, `[[`, "chapters")), appendices)
  check_packages(chapters)

  # Copy the textbook into a temporary directory so that nothing in the
  # project (other than the final output) is touched
  # (resolving symlinks, since on macOS Quarto otherwise mangles the path
  # when it copies the HTML pages' figures)
  build_dir <- tempfile("textbook_")
  dir.create(build_dir)
  build_dir <- normalizePath(build_dir)
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
    execute = list(warning = FALSE, message = FALSE)
  )
  if (book_format == "pdf") {
    config$format <- list(pdf = list(
      documentclass = "scrreprt",
      toc = TRUE,
      `toc-depth` = 1,
      `number-sections` = TRUE
    ))
  } else {
    config$format <- list(html = list(
      toc = TRUE,
      `number-sections` = TRUE
    ))
  }
  if (length(appendices) > 0) {
    config$book$appendices <- as.list(appendices)
  }
  if (!include_solutions) {
    write_solution_filter(build_dir)
    config$filters <- list("remove-solutions.lua")
  }
  yaml::write_yaml(config, file.path(build_dir, "_quarto.yml"),
                   handlers = list(logical = yaml::verbatim_logical))

  # Render the book and copy the output back into the project
  message("Rendering ", length(chapters), " chapters to ",
          toupper(book_format), " (this will take several minutes)...")
  quarto::quarto_render(build_dir, output_format = book_format,
                        as_job = FALSE)
  book_dir <- file.path(build_dir, "_book")
  if (book_format == "pdf") {
    pdf <- list.files(book_dir, pattern = "\\.pdf$", full.names = TRUE)
    file.copy(pdf[1], output_file, overwrite = TRUE)
  } else {
    # The HTML book is a folder of pages, so replace the old folder whole
    unlink(output_file, recursive = TRUE)
    dir.create(output_file)
    file.copy(list.files(book_dir, full.names = TRUE), output_file,
              recursive = TRUE)
  }
  message("Done: ", normalizePath(output_file))
  invisible(output_file)
}

# The GitHub Action sets BOOK_SKIP_RENDER when it only needs the functions
# above (e.g., to list the packages to install)
if (!as.logical(Sys.getenv("BOOK_SKIP_RENDER", "FALSE"))) {
  render_book()
}
