# Small, transparent functions used by Blog Post 8.

bootstrap_mean <- function(x, B = 1000) {
  stopifnot(is.numeric(x), length(x) > 1L, B > 0L)
  replicate(B, mean(sample(x, size = length(x), replace = TRUE)))
}

bootstrap_ci <- function(x, levels = 0.95, B = 1000) {
  stopifnot(all(levels > 0 & levels < 1))
  draws <- bootstrap_mean(x, B = B)
  bounds <- lapply(levels, function(level) {
    alpha <- (1 - level) / 2
    unname(quantile(draws, probs = c(alpha, 1 - alpha), type = 7))
  })
  data.frame(
    confidence = levels,
    lower = vapply(bounds, `[`, numeric(1), 1L),
    upper = vapply(bounds, `[`, numeric(1), 2L)
  )
}

simulate_coverage <- function(reps, n, population_mean, population_sd,
                              levels = c(0.90, 0.95, 0.99), B = 499) {
  stopifnot(reps > 0L, n > 1L, population_sd > 0, B > 0L)
  rows <- vector("list", reps * length(levels))
  index <- 1L
  for (r in seq_len(reps)) {
    sample_x <- rnorm(n, mean = population_mean, sd = population_sd)
    intervals <- bootstrap_ci(sample_x, levels = levels, B = B)
    intervals$replicate <- r
    intervals$covered <- intervals$lower <= population_mean &
      population_mean <= intervals$upper
    rows[index:(index + length(levels) - 1L)] <- split(intervals, seq_len(nrow(intervals)))
    index <- index + length(levels)
  }
  interval_data <- do.call(rbind, rows)
  summary_data <- aggregate(
    covered ~ confidence, data = interval_data,
    FUN = function(x) mean(x)
  )
  names(summary_data)[names(summary_data) == "covered"] <- "coverage"
  summary_data$replicates <- reps
  list(summary = summary_data, intervals = interval_data)
}

simulate_null_t <- function(reps, n, null_mean = 0, population_sd = 1) {
  stopifnot(reps > 0L, n > 1L, population_sd > 0)
  replicate(reps, {
    x <- rnorm(n, mean = null_mean, sd = population_sd)
    (mean(x) - null_mean) / (sd(x) / sqrt(n))
  })
}
