# Reproduces the weighted CPS summaries from an IPUMS Basic Monthly CSV extract.
# Required variables: YEAR, AGE, EMPSTAT, EDUC, WTFINL.
# Place cps_00003.csv in data/ before running this script.

script_arg <- commandArgs(trailingOnly = FALSE)
script_file <- sub("^--file=", "", script_arg[grepl("^--file=", script_arg)])
post_dir <- if (length(script_file) == 1) dirname(normalizePath(script_file)) else normalizePath(getwd())
data_path <- file.path(post_dir, "data", "cps_00003.csv")
if (!file.exists(data_path)) {
  stop("Missing data/cps_00003.csv. Download the IPUMS CPS Basic Monthly extract described in README.md.")
}

cps <- read.csv(data_path, colClasses = c(YEAR = "integer", AGE = "integer", EMPSTAT = "integer",
                                          EDUC = "integer", WTFINL = "numeric"))
education_group <- function(x) {
  out <- rep(NA_character_, length(x))
  out[x %in% c(2, 10, 20, 30, 40, 50, 60, 71)] <- "Less than high school"
  out[x == 73] <- "High school"
  out[x %in% c(81, 91, 92)] <- "Some college / associate"
  out[x == 111] <- "Bachelor's degree"
  out[x %in% c(123, 124, 125)] <- "Graduate degree"
  factor(out, levels = c("Less than high school", "High school", "Some college / associate",
                         "Bachelor's degree", "Graduate degree"))
}

cps$education <- education_group(cps$EDUC)
analysis <- cps[cps$AGE >= 25 & cps$AGE <= 64 & cps$EMPSTAT %in% c(10, 12, 21, 22) &
                !is.na(cps$education) & !is.na(cps$WTFINL) & cps$WTFINL > 0, ]
analysis$unemployed_weight <- analysis$WTFINL * (analysis$EMPSTAT %in% c(21, 22))

annual <- aggregate(cbind(labor_force_population = WTFINL, unemployed_weight) ~ YEAR + education,
                    data = analysis, FUN = sum)
annual$unemployment_rate <- annual$unemployed_weight / annual$labor_force_population
annual <- annual[order(annual$YEAR, annual$education), ]
write.csv(annual, file.path(post_dir, "results", "annual_unemployment_by_education.csv"), row.names = FALSE)
source(file.path(post_dir, "make_figures.R"))
