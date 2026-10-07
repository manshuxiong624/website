# Reproducible data acquisition and summaries for Citi Bike Blog Post 4.
# Run from any working directory; data paths resolve relative to this script.

required <- c("dplyr", "readr", "tidyr", "lubridate", "tibble", "ggplot2", "knitr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(paste0("Install missing packages first: install.packages(c(",
              paste(sprintf('"%s"', missing), collapse = ", "), "))"))
}

script_file <- tryCatch(normalizePath(sys.frame(1)$ofile, winslash = "/", mustWork = TRUE),
                        error = function(e) NA_character_)
if (is.na(script_file)) {
  script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(script_arg)) {
    script_file <- normalizePath(sub("^--file=", "", script_arg[[1]]), winslash = "/", mustWork = FALSE)
  }
}
project_dir <- if (!is.na(script_file)) dirname(script_file) else getwd()
data_dir <- file.path(project_dir, "data")
raw_dir <- file.path(data_dir, "raw")
derived_dir <- file.path(data_dir, "derived")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)

archive_url <- "https://s3.amazonaws.com/tripdata/202401-citibike-tripdata.zip"
archive_file <- file.path(raw_dir, "202401-citibike-tripdata.zip")
archive_members <- function(path) {
  tryCatch(
    unzip(path, list = TRUE)$Name,
    error = function(e) stop(
      "Cannot read the Citi Bike ZIP archive at ", path, ". It may be incomplete or corrupt. ",
      "Move the damaged file out of data/raw and rerun this script. Details: ",
      conditionMessage(e), call. = FALSE
    )
  )
}

if (!file.exists(archive_file)) {
  options(timeout = max(3600, getOption("timeout")))
  partial_file <- tempfile(pattern = ".citibike-download-", tmpdir = raw_dir, fileext = ".zip.part")
  tryCatch({
    download_status <- utils::download.file(archive_url, partial_file, mode = "wb", quiet = FALSE)
    if (!isTRUE(download_status == 0) || !file.exists(partial_file) || file.info(partial_file)$size == 0) {
      stop("The archive download did not complete successfully.", call. = FALSE)
    }
    downloaded_members <- archive_members(partial_file)
    if (!any(grepl("\\.csv$", downloaded_members, ignore.case = TRUE))) {
      stop("The downloaded archive contains no CSV files.", call. = FALSE)
    }
    if (!file.rename(partial_file, archive_file)) {
      stop("The archive downloaded, but could not be moved into data/raw.", call. = FALSE)
    }
  }, error = function(e) {
    if (file.exists(partial_file)) unlink(partial_file)
    stop("Could not acquire the January 2024 Citi Bike archive. Check your internet connection and try again. Details: ",
         conditionMessage(e), call. = FALSE)
  })
}

csv_members <- archive_members(archive_file)
csv_members <- sort(csv_members[grepl("\\.csv$", csv_members, ignore.case = TRUE)])
if (length(csv_members) == 0) stop("The Citi Bike archive contains no CSV files.")

read_trip_member <- function(member) {
  con <- unz(archive_file, member, open = "rb")
  on.exit(close(con))
  readr::read_csv(
    con,
    col_select = c(started_at, ended_at, member_casual),
    locale = readr::locale(tz = "America/New_York"),
    col_types = readr::cols(
      started_at = readr::col_datetime(format = "%Y-%m-%d %H:%M:%OS"),
      ended_at = readr::col_datetime(format = "%Y-%m-%d %H:%M:%OS"),
      member_casual = readr::col_character(),
      .default = readr::col_skip()
    ),
    name_repair = "minimal", show_col_types = FALSE, progress = FALSE
  )
}

trips_raw <- dplyr::bind_rows(lapply(csv_members, read_trip_member))
rows_read <- nrow(trips_raw)

# The published timestamps are local clock time without a UTC offset. Retain
# their New York hour and date for descriptive timing comparisons.
trips <- trips_raw |>
  dplyr::mutate(
    trip_minutes = as.numeric(difftime(ended_at, started_at, units = "mins")),
    trip_date = as.Date(started_at, tz = "America/New_York"),
    hour = lubridate::hour(started_at),
    weekday_num = lubridate::wday(started_at, week_start = 1),
    weekday = factor(weekday_num, levels = 1:7,
                     labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
    day_type = ifelse(weekday_num <= 5, "Weekday", "Weekend"),
    rider_type = tolower(trimws(member_casual))
  )

trips_valid <- trips |>
  dplyr::filter(
    !is.na(started_at), !is.na(ended_at), !is.na(trip_date),
    trip_date >= as.Date("2024-01-01"), trip_date < as.Date("2024-02-01"),
    !is.na(trip_minutes), trip_minutes > 0,
    rider_type %in% c("member", "casual")
  )
rows_omitted <- rows_read - nrow(trips_valid)

calendar <- tibble::tibble(date = seq(as.Date("2024-01-01"), as.Date("2024-01-31"), by = "day")) |>
  dplyr::mutate(
    weekday_num = lubridate::wday(date, week_start = 1),
    weekday = factor(weekday_num, levels = 1:7,
                     labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
    day_type = ifelse(weekday_num <= 5, "Weekday", "Weekend")
  )

daily_rides <- trips_valid |>
  dplyr::count(date = trip_date, name = "rides") |>
  dplyr::right_join(calendar, by = "date") |>
  dplyr::mutate(rides = tidyr::replace_na(rides, 0L)) |>
  dplyr::arrange(date) |>
  dplyr::select(date, weekday, day_type, rides)

hour_counts <- trips_valid |>
  dplyr::count(date = trip_date, hour, name = "rides")
hour_grid <- tidyr::crossing(calendar, hour = 0:23) |>
  dplyr::left_join(hour_counts, by = c("date", "hour")) |>
  dplyr::mutate(rides = tidyr::replace_na(rides, 0L))

hourly_by_day_type <- hour_grid |>
  dplyr::group_by(day_type, hour) |>
  dplyr::summarise(mean_rides_per_day = mean(rides), .groups = "drop")

weekday_hour_mean <- hour_grid |>
  dplyr::group_by(weekday, hour) |>
  dplyr::summarise(mean_rides_per_day = mean(rides), days = dplyr::n_distinct(date), .groups = "drop")

daily_by_day_type <- daily_rides |>
  dplyr::group_by(day_type) |>
  dplyr::summarise(days = dplyr::n(), mean_daily_rides = mean(rides), .groups = "drop")

duration_sample <- trips_valid |>
  dplyr::filter(trip_minutes >= 1, trip_minutes < 120) |>
  dplyr::mutate(bin_start = floor(trip_minutes / 5) * 5)

duration_histogram <- duration_sample |>
  dplyr::count(rider_type, bin_start, name = "rides") |>
  dplyr::group_by(rider_type) |>
  tidyr::complete(bin_start = seq(0, 115, by = 5), fill = list(rides = 0L)) |>
  dplyr::mutate(share = rides / sum(rides)) |>
  dplyr::ungroup()

duration_medians <- duration_histogram |>
  dplyr::arrange(rider_type, bin_start) |>
  dplyr::group_by(rider_type) |>
  dplyr::mutate(cumulative_rides = cumsum(rides), total_rides = sum(rides)) |>
  dplyr::filter(cumulative_rides >= (total_rides + 1) / 2) |>
  dplyr::slice_head(n = 1) |>
  dplyr::ungroup() |>
  dplyr::mutate(approx_median_bin_center = bin_start + 2.5) |>
  dplyr::select(rider_type, total_rides, approx_median_bin_center)

fmt_n <- function(x) format(round(x), big.mark = ",", scientific = FALSE)
peak_hour <- function(type) {
  hourly_by_day_type |>
    dplyr::filter(day_type == type) |>
    dplyr::slice_max(mean_rides_per_day, n = 1, with_ties = FALSE) |>
    dplyr::pull(hour)
}

mean_weekday <- daily_by_day_type$mean_daily_rides[daily_by_day_type$day_type == "Weekday"]
mean_weekend <- daily_by_day_type$mean_daily_rides[daily_by_day_type$day_type == "Weekend"]
weekday_lift_pct <- (mean_weekday / mean_weekend - 1) * 100
weekday_8 <- hourly_by_day_type$mean_rides_per_day[hourly_by_day_type$day_type == "Weekday" & hourly_by_day_type$hour == 8]
weekday_13 <- hourly_by_day_type$mean_rides_per_day[hourly_by_day_type$day_type == "Weekday" & hourly_by_day_type$hour == 13]
weekday_17 <- hourly_by_day_type$mean_rides_per_day[hourly_by_day_type$day_type == "Weekday" & hourly_by_day_type$hour == 17]
commute_vs_midday <- (weekday_8 + weekday_17) / weekday_13

summary_stats <- tibble::tibble(
  month = "2024-01",
  valid_trips = nrow(trips_valid),
  omitted_rows = rows_omitted,
  weekday_days = sum(calendar$weekday_num <= 5),
  weekend_days = sum(calendar$weekday_num >= 6),
  mean_daily_rides_weekday = mean_weekday,
  mean_daily_rides_weekend = mean_weekend,
  weekday_lift_percent = weekday_lift_pct,
  weekday_peak_hour = peak_hour("Weekday"),
  weekend_peak_hour = peak_hour("Weekend"),
  weekday_08_17_over_13_hourly = commute_vs_midday
)

environment_packages <- c("dplyr", "readr", "tidyr", "lubridate", "tibble", "ggplot2", "knitr")
package_versions <- vapply(environment_packages, function(pkg) {
  as.character(utils::packageVersion(pkg))
}, character(1))

metadata <- tibble::tibble(
  source_landing_page = "https://citibikenyc.com/system-data",
  source_archive = archive_url,
  data_sharing_policy = "https://citibikenyc.com/data-sharing-policy",
  archive_local_date = as.character(as.Date(file.info(archive_file)$mtime)),
  archive_md5 = unname(tools::md5sum(archive_file)),
  r_version = as.character(getRversion()),
  platform = R.version$platform,
  package_versions = paste(names(package_versions), package_versions, sep = "=", collapse = "; "),
  rows_read = rows_read,
  valid_january_rows = nrow(trips_valid),
  rows_omitted = rows_omitted,
  csv_members = paste(csv_members, collapse = "; ")
)

readr::write_csv(daily_rides, file.path(derived_dir, "daily_rides.csv"))
readr::write_csv(hourly_by_day_type, file.path(derived_dir, "hourly_by_day_type.csv"))
readr::write_csv(weekday_hour_mean, file.path(derived_dir, "weekday_hour_mean.csv"))
readr::write_csv(duration_histogram, file.path(derived_dir, "duration_histogram.csv"))
readr::write_csv(duration_medians, file.path(derived_dir, "duration_median_bins.csv"))
readr::write_csv(summary_stats, file.path(derived_dir, "summary_stats.csv"))
readr::write_csv(metadata, file.path(derived_dir, "source_metadata.csv"))
capture.output(utils::sessionInfo(), file = file.path(derived_dir, "session_info.txt"))

message("Saved derived tables and environment details in: ", derived_dir)
message("Valid January trips: ", fmt_n(nrow(trips_valid)),
        " | excluded rows: ", fmt_n(rows_omitted))
