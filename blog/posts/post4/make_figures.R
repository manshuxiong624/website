# Rebuild the three figures from data/derived tables.

required <- c("readr", "ggplot2", "dplyr")
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
derived_dir <- file.path(project_dir, "data", "derived")
image_dir <- file.path(project_dir, "images")
dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)

hourly <- readr::read_csv(file.path(derived_dir, "hourly_by_day_type.csv"), show_col_types = FALSE)
weekday_hour <- readr::read_csv(file.path(derived_dir, "weekday_hour_mean.csv"), show_col_types = FALSE)
duration <- readr::read_csv(file.path(derived_dir, "duration_histogram.csv"), show_col_types = FALSE)
weekday_order <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
weekday_hour$weekday <- factor(weekday_hour$weekday, levels = weekday_order)

svg_device <- if (requireNamespace("svglite", quietly = TRUE)) {
  svglite::svglite
} else {
  grDevices::svg
}

plot_theme <- ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold"),
    panel.grid.minor = ggplot2::element_blank(),
    legend.position = "top"
  )

p_hourly <- ggplot2::ggplot(hourly,
                            ggplot2::aes(x = hour, y = mean_rides_per_day, color = day_type)) +
  ggplot2::geom_line(linewidth = 1.15) +
  ggplot2::geom_point(size = 1.5) +
  ggplot2::scale_color_manual(values = c(Weekday = "#087e8b", Weekend = "#e07a5f"), name = "Day type") +
  ggplot2::scale_x_continuous(breaks = seq(0, 22, by = 2), labels = sprintf("%02d:00", seq(0, 22, by = 2))) +
  ggplot2::scale_y_continuous(labels = function(x) format(round(x), big.mark = ",")) +
  ggplot2::labs(
    title = "The commute is still visible - even in January",
    subtitle = "Average rides per clock hour | January 2024",
    x = "Hour of day (local time)", y = "Mean trip starts per day"
  ) + plot_theme

p_heatmap <- ggplot2::ggplot(weekday_hour,
                             ggplot2::aes(x = hour, y = weekday, fill = mean_rides_per_day)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.35) +
  ggplot2::scale_x_continuous(breaks = seq(0, 22, by = 2), labels = sprintf("%02d", seq(0, 22, by = 2)), expand = c(0, 0)) +
  ggplot2::scale_y_discrete(limits = rev(weekday_order)) +
  ggplot2::scale_fill_gradient(low = "#eef4f1", high = "#087e8b",
                               labels = function(x) format(round(x), big.mark = ","),
                               name = "Mean rides\nper day") +
  ggplot2::labs(
    title = "Two rush hours, one quieter afternoon",
    subtitle = "Average trip starts by weekday and hour | January 2024",
    x = "Hour of day (local time)", y = NULL
  ) +
  plot_theme + ggplot2::theme(panel.grid = ggplot2::element_blank(),
                              axis.text.y = ggplot2::element_text(face = "bold"),
                              legend.position = "right")

p_duration <- ggplot2::ggplot(duration,
                              ggplot2::aes(x = bin_start + 2.5, y = share * 100, color = rider_type)) +
  ggplot2::geom_line(linewidth = 1.15) +
  ggplot2::scale_color_manual(values = c(member = "#087e8b", casual = "#e07a5f"),
                              breaks = c("member", "casual"),
                              labels = c(member = "Members", casual = "Casual riders"),
                              name = "Rider type") +
  ggplot2::scale_x_continuous(breaks = seq(0, 100, by = 20), limits = c(0, 120), expand = c(0, 0)) +
  ggplot2::labs(
    title = "Casual rides tend to last longer",
    subtitle = "Trip duration distribution | January 2024",
    x = "Trip duration (minutes; five-minute bins)",
    y = "Share of trips in rider group (%)"
  ) + plot_theme

ggplot2::ggsave(file.path(image_dir, "hourly_rhythm.svg"), p_hourly,
                width = 9, height = 5.2, device = svg_device, bg = "white")
ggplot2::ggsave(file.path(image_dir, "weekday_hour_heatmap.svg"), p_heatmap,
                width = 9, height = 5.7, device = svg_device, bg = "white")
ggplot2::ggsave(file.path(image_dir, "duration_by_rider_type.svg"), p_duration,
                width = 9, height = 5.2, device = svg_device, bg = "white")

message("Saved three SVG figures in: ", image_dir)
