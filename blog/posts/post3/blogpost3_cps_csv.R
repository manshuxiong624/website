# Blog Post 3: Education and unemployment in the U.S. labor market
# Reproducible analysis for the IPUMS CPS Basic Monthly extract (2015--2024).
#
# Put cps_00003.csv in data/ and run this script from the project folder.

data_path <- file.path("data", "cps_00003.csv")
results_dir <- "real_results"
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(data_path)) {
  stop("Place cps_00003.csv in the project's data/ folder, then run again.")
}

# Read only the variables used in the analysis. The selected CSV has 13.7 million
# rows, so this may take several minutes and requires several GB of free memory.
all_names <- c(
  "YEAR", "SERIAL", "MONTH", "HWTFINL", "CPSID", "ASECFLAG", "PERNUM",
  "WTFINL", "CPSIDP", "CPSIDV", "AGE", "SEX", "EMPSTAT", "EDUC"
)
classes <- rep("NULL", length(all_names))
names(classes) <- all_names
classes[c("YEAR", "AGE", "SEX", "EMPSTAT", "EDUC")] <- "integer"
classes["WTFINL"] <- "numeric"

cps <- read.csv(
  data_path,
  colClasses = classes,
  na.strings = "",
  check.names = FALSE
)

# IPUMS CPS EDUC codes in the 2015--2024 Basic Monthly samples.
education_group <- function(x) {
  out <- rep(NA_character_, length(x))
  out[x %in% c(2, 10, 20, 30, 40, 50, 60, 71)] <- "Less than high school"
  out[x == 73] <- "High school"
  out[x %in% c(81, 91, 92)] <- "Some college / associate"
  out[x == 111] <- "Bachelor's degree"
  out[x %in% c(123, 124, 125)] <- "Graduate degree"
  factor(
    out,
    levels = c(
      "Less than high school", "High school", "Some college / associate",
      "Bachelor's degree", "Graduate degree"
    )
  )
}

# EMPSTAT 10 and 12 are employed; 21 and 22 are unemployed.
# This defines unemployment as unemployed / civilian labor force.
cps$education <- education_group(cps$EDUC)
cps$age_group <- cut(
  cps$AGE,
  breaks = c(24, 34, 54, 64),
  labels = c("25--34", "35--54", "55--64")
)

analysis <- cps[
  cps$AGE >= 25 & cps$AGE <= 64 &
    cps$EMPSTAT %in% c(10, 12, 21, 22) &
    !is.na(cps$education) &
    !is.na(cps$WTFINL) & cps$WTFINL > 0,
]
analysis$unemployed_weight <- analysis$WTFINL * (analysis$EMPSTAT %in% c(21, 22))

# Every rate uses WTFINL, IPUMS CPS's final person-level Basic Monthly weight.
annual <- aggregate(
  cbind(labor_force_population = WTFINL, unemployed_weight) ~ YEAR + education,
  data = analysis,
  FUN = sum
)
annual$unemployment_rate <- annual$unemployed_weight / annual$labor_force_population
annual <- annual[order(annual$YEAR, annual$education), ]

annual_age <- aggregate(
  cbind(labor_force_population = WTFINL, unemployed_weight) ~ YEAR + age_group + education,
  data = analysis[!is.na(analysis$age_group), ],
  FUN = sum
)
annual_age$unemployment_rate <- annual_age$unemployed_weight / annual_age$labor_force_population
annual_age <- annual_age[order(annual_age$YEAR, annual_age$age_group, annual_age$education), ]

write.csv(
  annual,
  file.path(results_dir, "annual_unemployment_by_education.csv"),
  row.names = FALSE
)
write.csv(
  annual_age,
  file.path(results_dir, "annual_unemployment_by_age_and_education.csv"),
  row.names = FALSE
)
write.csv(
  annual[annual$YEAR %in% c(2019, 2020, 2024), ],
  file.path(results_dir, "headline_results_table.csv"),
  row.names = FALSE
)

source("make_figures.R")

