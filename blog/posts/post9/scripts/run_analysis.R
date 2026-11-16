run_post9_analysis <- function() {
  # Quarto's default execution directory is the directory containing the QMD.
  if (!file.exists("scripts/analysis.py")) {
    stop("Open blogpost9.qmd from its post9 folder, or render it through your website project.")
  }
  candidates <- unique(c(
    Sys.getenv("POST9_PYTHON"),
    file.path(".venv", if (.Platform$OS.type == "windows") "Scripts/python.exe" else "bin/python"),
    path.expand("~/aeds6400-python/bin/python"),
    path.expand("~/aeds6400-python/Scripts/python.exe"),
    unname(Sys.which(c("python3", "python"))),
    "/opt/anaconda3/bin/python"
  ))
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  python <- NULL
  for (candidate in candidates) {
    status <- suppressWarnings(system2(candidate,
      c("-c", shQuote("import sklearn, pandas, numpy, matplotlib")),
      stdout = FALSE, stderr = FALSE))
    if (identical(status, 0L)) { python <- candidate; break }
  }
  if (is.null(python)) {
    stop(paste(
      "Python with scikit-learn, pandas, numpy and matplotlib is required.",
      "Follow README.md's one-time setup, or set Sys.setenv(POST9_PYTHON='path/to/python')."
    ))
  }
  log_file <- tempfile("post9_analysis_", fileext = ".log")
  status <- system2(python, shQuote("scripts/analysis.py"), stdout = log_file, stderr = log_file)
  if (status != 0L) stop(paste(readLines(log_file, warn = FALSE), collapse = "\n"))
  invisible(python)
}
