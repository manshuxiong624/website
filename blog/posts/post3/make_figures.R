# Creates the three figures from the weighted CPS summary tables.
if (!exists("results_dir", inherits = FALSE)) {
  results_dir <- "real_results"
}
figure_dir <- file.path(results_dir, "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

annual <- read.csv(file.path(results_dir, "annual_unemployment_by_education.csv"))
annual_age <- read.csv(file.path(results_dir, "annual_unemployment_by_age_and_education.csv"))

education_order <- c(
  "Less than high school", "High school", "Some college / associate",
  "Bachelor's degree", "Graduate degree"
)
education_colors <- c("#9E2F2F", "#D77828", "#B8A21A", "#3B7EA1", "#22543D")
annual$education <- factor(annual$education, levels = education_order)
annual_age$education <- factor(annual_age$education, levels = education_order)

# Figure 1: annual weighted unemployment rates by education.
png(file.path(figure_dir, "figure_1_education_trends.png"),
    width = 2200, height = 1300, res = 220)
par(mar = c(4.5, 5, 3.5, 1), family = "sans")
plot(NA, xlim = c(2015, 2024), ylim = c(0, 0.13), xlab = "", ylab = "Unemployment rate",
     xaxt = "n", yaxt = "n", main = "Unemployment rose for every education group in 2020")
axis(1, at = 2015:2024)
axis(2, at = seq(0, 0.12, 0.02), labels = paste0(seq(0, 12, 2), "%"), las = 1)
abline(v = 2020, lty = 2, col = "gray55")
for (i in seq_along(education_order)) {
  x <- annual[annual$education == education_order[i], ]
  lines(x$YEAR, x$unemployment_rate, type = "o", lwd = 2.7, pch = 16,
        col = education_colors[i])
}
legend("topleft", legend = education_order, col = education_colors, lwd = 2.7,
       pch = 16, bty = "n", cex = 0.9)
mtext("IPUMS CPS Basic Monthly, adults ages 25--64 in the civilian labor force; weighted using WTFINL.",
      side = 1, line = 3.1, cex = 0.72)
dev.off()

# Figure 2: the size of the initial pandemic shock, rather than another
# presentation of unemployment levels.
pre_pandemic <- annual[annual$YEAR == 2019, c("education", "unemployment_rate")]
shock_year <- annual[annual$YEAR == 2020, c("education", "unemployment_rate")]
names(pre_pandemic)[2] <- "rate_2019"
names(shock_year)[2] <- "rate_2020"
pandemic_shock <- merge(pre_pandemic, shock_year, by = "education", sort = FALSE)
pandemic_shock$increase_pp <- 100 * (pandemic_shock$rate_2020 - pandemic_shock$rate_2019)
pandemic_shock <- pandemic_shock[match(education_order, pandemic_shock$education), ]
write.csv(pandemic_shock,
          file.path(results_dir, "pandemic_shock_by_education.csv"), row.names = FALSE)

png(file.path(figure_dir, "figure_2_pandemic_comparison.png"),
    width = 2200, height = 1300, res = 220)
par(mar = c(8, 12, 3.5, 1), family = "sans")
bp <- barplot(pandemic_shock$increase_pp, horiz = TRUE,
              col = education_colors[match(pandemic_shock$education, education_order)],
              xlim = c(0, 7), xlab = "Increase in unemployment rate (percentage points)",
              names.arg = pandemic_shock$education, las = 1, xaxt = "n",
              main = "The 2020 unemployment increase was largest for less-educated workers")
axis(1, at = 0:7, labels = paste0(0:7, " pp"))
text(pandemic_shock$increase_pp, bp,
     labels = paste0(sprintf("%.1f", pandemic_shock$increase_pp), " pp"), pos = 4, cex = 0.9)
mtext("Change from the 2019 annual average to the 2020 annual average; IPUMS CPS Basic Monthly, weighted using WTFINL.",
      side = 1, line = 5.3, cex = 0.72)
dev.off()

# Figure 3: 2024 composition of the labor force and unemployed population.
# This asks a different question: which groups are over-represented among
# unemployed workers relative to their share of the civilian labor force?
latest <- annual[annual$YEAR == 2024, ]
latest$labor_force_share <- latest$labor_force_population / sum(latest$labor_force_population)
latest$unemployed_share <- latest$unemployed_weight / sum(latest$unemployed_weight)
latest$share_gap_pp <- 100 * (latest$unemployed_share - latest$labor_force_share)
latest <- latest[match(education_order, latest$education), ]
write.csv(latest[, c("education", "labor_force_share", "unemployed_share", "share_gap_pp")],
          file.path(results_dir, "labor_force_vs_unemployed_share_2024.csv"), row.names = FALSE)

png(file.path(figure_dir, "figure_3_age_education_trends.png"),
    width = 2200, height = 1300, res = 220)
par(mar = c(8, 12, 3.5, 2), family = "sans")
y <- seq_along(education_order)
plot(NA, xlim = c(0, 0.32), ylim = c(0.5, 5.5), xlab = "Share of people in each group",
     ylab = "", yaxt = "n", xaxt = "n",
     main = "In 2024, less-educated workers were over-represented among the unemployed")
axis(1, at = seq(0, 0.30, 0.05), labels = paste0(seq(0, 30, 5), "%"))
axis(2, at = y, labels = education_order, las = 1)
segments(latest$labor_force_share, y, latest$unemployed_share, y, lwd = 3, col = "gray65")
points(latest$labor_force_share, y, pch = 16, cex = 1.7, col = "#3B7EA1")
points(latest$unemployed_share, y, pch = 16, cex = 1.7, col = "#B44D4D")
legend("bottomright", legend = c("Share of civilian labor force", "Share of unemployed workers"),
       col = c("#3B7EA1", "#B44D4D"), pch = 16, bty = "n")
mtext("Adults ages 25--64 in the civilian labor force; IPUMS CPS Basic Monthly, weighted using WTFINL.",
      side = 1, line = 5.3, cex = 0.72)
dev.off()
