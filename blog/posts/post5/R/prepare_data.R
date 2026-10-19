# Download and prepare 2024 ACS income estimates and TIGER/Line county geography.
# Run from the Post5_GIS project root.

required <- c("sf", "dplyr", "readr", "jsonlite")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: ", paste(missing, collapse = ", "))
}

options(timeout = 300)
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("data/raw/tiger_2024", recursive = TRUE, showWarnings = FALSE)

# Ten counties in the Philadelphia-Camden-Wilmington area for this comparison.
metro_fips <- c(
  "42017", "42029", "42045", "42091", "42101", # PA: Bucks, Chester, Delaware, Montgomery, Philadelphia
  "34005", "34007", "34015", "34033",          # NJ: Burlington, Camden, Gloucester, Salem
  "10003"                                         # DE: New Castle
)
state_fips <- c("42", "34", "10")
api_key <- Sys.getenv("CENSUS_API_KEY")
if (!nzchar(api_key)) {
  stop(
    "Census API key not found. Request and activate a free key, then set ",
    "CENSUS_API_KEY in your user-level ~/.Renviron file. See README.md."
  )
}

fetch_state <- function(state) {
  url <- paste0(
    "https://api.census.gov/data/2024/acs/acs5?get=NAME%2CB19013_001E%2CB19013_001M",
    "&for=county%3A%2A&in=state%3A", state,
    "&key=", utils::URLencode(api_key, reserved = TRUE)
  )
  message("Fetching 2024 ACS county data for state FIPS ", state, "...")
  response <- tryCatch(
    jsonlite::fromJSON(url, simplifyVector = TRUE),
    error = function(e) {
      stop(
        "Census API request failed for state FIPS ", state,
        ". Check that your API key is activated and try again. Original error: ",
        conditionMessage(e), call. = FALSE
      )
    }
  )
  out <- as.data.frame(response[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(out) <- response[1, ]
  out
}

acs <- do.call(rbind, lapply(state_fips, fetch_state))
acs$GEOID <- paste0(acs$state, acs$county)
acs <- acs[acs$GEOID %in% metro_fips, c("GEOID", "NAME", "B19013_001E", "B19013_001M")]
names(acs) <- c("GEOID", "county", "income", "income_moe_90")
acs$income <- suppressWarnings(as.numeric(acs$income))
acs$income_moe_90 <- suppressWarnings(as.numeric(acs$income_moe_90))
if (nrow(acs) != length(metro_fips) || anyNA(acs$income)) {
  stop("The Census API response did not contain all 10 county income estimates.")
}
readr::write_csv(acs, "data/processed/acs5_2024_income.csv")

tiger_zip <- "data/raw/tiger_2024/tl_2024_us_county.zip"
if (!file.exists(tiger_zip)) {
  tiger_url <- "https://www2.census.gov/geo/tiger/TIGER2024/COUNTY/tl_2024_us_county.zip"
  message("Downloading 2024 TIGER/Line county boundaries...")
  utils::download.file(tiger_url, tiger_zip, mode = "wb", quiet = FALSE)
}
unzip_dir <- "data/raw/tiger_2024/unzipped"
dir.create(unzip_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.exists(file.path(unzip_dir, "tl_2024_us_county.shp"))) {
  utils::unzip(tiger_zip, exdir = unzip_dir)
}
counties <- sf::st_read(file.path(unzip_dir, "tl_2024_us_county.shp"), quiet = TRUE)
region <- counties[counties$GEOID %in% metro_fips, ]
region <- dplyr::left_join(region, acs, by = "GEOID")
region <- sf::st_transform(region, 5070)
sf::st_write(region, "data/processed/philadelphia_metro_income.gpkg", delete_dsn = TRUE, quiet = TRUE)
message("Saved ", nrow(region), " counties and their 2024 ACS income estimates.")
