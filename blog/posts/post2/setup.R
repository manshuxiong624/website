# Install into this project rather than modifying a system R library.
dir.create('.R-library',showWarnings=FALSE)
.libPaths(c(normalizePath('.R-library'),.libPaths()))
packages <- c('rvest','dplyr','readr','stringr','ggplot2','httr','commonmark','jsonlite')
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) install.packages(missing,repos='https://cloud.r-project.org',lib='.R-library')
