# Run from the project root. Default: reproduce from saved factual HTML extracts.
# Rscript R/01_scrape.R --live requests a new snapshot from the public website.
suppressPackageStartupMessages({
  library(rvest); library(dplyr); library(readr); library(stringr)
})
dir.create('data', showWarnings = FALSE)
dir.create('data/snapshots', showWarnings = FALSE)
base_url <- 'https://galmangroup.com'
index_url <- paste0(base_url, '/philadelphia/')
live <- '--live' %in% commandArgs(trailingOnly = TRUE)

fetch_html <- function(url) {
  Sys.sleep(2) # Sequential requests; never bypass login, CAPTCHA or rate limits.
  response <- httr::GET(url, httr::timeout(45),
    httr::user_agent('PhillyRentClassProject/1.0 (educational research; limited requests)'))
  httr::stop_for_status(response) # Stop on errors, including 403 and 429.
  rvest::read_html(httr::content(response, as = 'raw'))
}

# Preserve only factual table cells, a property name and its location heading.
# No images, tracking scripts, contact forms or full marketing descriptions.
make_extract <- function(doc, path) {
  tables <- html_elements(doc, 'table')
  keep <- vapply(html_table(tables, convert = FALSE), function(x)
    all(c('Model', 'Beds', 'Baths', 'Rent', 'Sq Ft') %in% names(x)), logical(1))
  if (sum(keep) != 1) stop('Expected exactly one rental table: ', path)
  table <- tables[[which(keep)]]
  xml2::xml_remove(html_elements(table, 'img,script,style,a'))
  html <- paste0('<!doctype html><html><head><meta charset="utf-8"></head><body>',
    as.character(html_element(doc, 'h1')), as.character(html_element(doc, 'h2')),
    as.character(table), '</body></html>')
  writeLines(html, path, useBytes = TRUE)
}

if (live) {
  # The stored robots file was manually reviewed on the original collection date.
  # If it changes, stop for a fresh review rather than assuming continuing access.
  response <- httr::GET(paste0(base_url, '/robots.txt'), httr::timeout(45))
  httr::stop_for_status(response)
  current <- str_trim(httr::content(response, as = 'text', encoding = 'UTF-8'))
  reviewed <- str_trim(paste(readLines('data/robots-reviewed.txt', warn = FALSE), collapse='\n'))
  if (!identical(current, reviewed)) stop('robots.txt changed. Review current site rules before collecting again.')
  index <- fetch_html(index_url)
  urls <- unique(html_attr(html_elements(index, 'a'), 'href'))
  urls <- urls[!is.na(urls) & str_detect(urls, '^https://galmangroup.com/property/') &
                 !str_detect(urls, '/the-flats-at-jenkintown/')]
  if (!length(urls)) stop('No property links found: inspect the directory layout.')
  # Includes property links present in the static directory, including Westfield.
  # The promotional Jenkintown banner is outside Philadelphia and is excluded.
  manifest <- list()
  for (i in seq_along(urls)) {
    url <- urls[i]
    slug <- str_remove(str_remove(url, fixed(paste0(base_url, '/property/'))), '/$')
    doc <- fetch_html(url)
    file <- paste0('data/snapshots/', slug, '.html')
    make_extract(doc, file)
    manifest[[i]] <- tibble(slug = slug, url = url, snapshot_file = file,
      retrieved_at_utc = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz='UTC'))
  }
  write_csv(bind_rows(manifest), 'data/sources.csv')
}

manifest <- read_csv('data/sources.csv', show_col_types = FALSE)
rows <- vector('list', nrow(manifest))
for (i in seq_len(nrow(manifest))) {
  doc <- read_html(manifest$snapshot_file[i])
  tab <- html_table(doc, convert = FALSE)[[1]]
  required <- c('Model','Beds','Baths','Rent','Sq Ft')
  if (!all(required %in% names(tab))) stop('Rental table schema changed.')
  rows[[i]] <- tibble(
    slug = manifest$slug[i], property = html_text2(html_element(doc,'h1')),
    location_heading = html_text2(html_element(doc,'h2')),
    model_raw = str_squish(tab$Model), beds_raw = str_squish(tab$Beds),
    baths_raw = str_squish(tab$Baths), rent_raw = str_squish(tab$Rent),
    sqft_raw = str_squish(tab[['Sq Ft']]), source_url = manifest$url[i],
    retrieved_at_utc = manifest$retrieved_at_utc[i])
}
raw <- bind_rows(rows)
if (anyDuplicated(raw[c('slug','model_raw','beds_raw','baths_raw')])) stop('Duplicate property/model rows require review.')
write_csv(raw, 'data/floorplans_raw.csv')
message('Parsed ', nrow(raw), ' floor-plan rows from ', nrow(manifest), ' property pages.')
