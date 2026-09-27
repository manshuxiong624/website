# Creates the three figures from the weighted CPS summary tables.
results_dir <- "real_results"
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

# Figure 2: three key years.
comparison <- annual[annual$YEAR %in% c(2019, 2020, 2024), ]
mat <- sapply(c(2019, 2020, 2024), function(y) {
  comparison$unemployment_rate[comparison$YEAR == y]
})
rownames(mat) <- education_order
png(file.path(figure_dir, "figure_2_pandemic_comparison.png"),
    width = 2200, height = 1300, res = 220)
par(mar = c(11, 5, 3.5, 1), family = "sans")
bp <- barplot(t(mat), beside = TRUE, col = c("#7C8798", "#B44D4D", "#2E6F95"),
              ylim = c(0, 0.14), ylab = "Unemployment rate", yaxt = "n",
              names.arg = education_order, las = 2,
              main = "The education gap widened during the COVID-19 shock")
axis(2, at = seq(0, 0.14, 0.02), labels = paste0(seq(0, 14, 2), "%"), las = 1)
text(bp, t(mat), labels = paste0(sprintf("%.1f", 100 * t(mat)), "%"), pos = 3, cex = 0.72)
legend("topleft", legend = c("2019", "2020", "2024"),
       fill = c("#7C8798", "#B44D4D", "#2E6F95"), bty = "n")
mtext("IPUMS CPS Basic Monthly, ages 25--64; weighted using WTFINL.",
      side = 1, line = 9.2, cex = 0.72)
dev.off()

# Figure 3: education gradient by age group.
png(file.path(figure_dir, "figure_3_age_education_trends.png"),
    width = 2500, height = 1200, res = 180)
layout(matrix(c(1, 2, 3, 4, 4, 4), nrow = 2, byrow = TRUE), heights = c(4, 0.65))
par(oma = c(0, 0, 3, 0), mar = c(4.5, 4.7, 3.2, 0.7), family = "sans")
for (age in c("25--34", "35--54", "55--64")) {
  d <- annual_age[annual_age$age_group == age, ]
  plot(NA, xlim = c(2015, 2024), ylim = c(0, 0.15), xlab = "", ylab = "Unemployment rate",
       xaxt = "n", yaxt = "n", main = paste("Ages", age))
  axis(1, at = c(2015, 2017, 2019, 2020, 2022, 2024))
  axis(2, at = seq(0, 0.14, 0.02), labels = paste0(seq(0, 14, 2), "%"), las = 1)
  abline(v = 2020, lty = 2, col = "gray55")
  for (i in seq_along(education_order)) {
    x <- d[d$education == education_order[i], ]
    lines(x$YEAR, x$unemployment_rate, type = "o", lwd = 2, pch = 16,
          col = education_colors[i])
  }
}
par(mar = c(0, 0, 0, 0))
plot.new()
legend("center", legend = education_order, col = education_colors,
       lwd = 2, pch = 16, bty = "n", horiz = TRUE, cex = 0.9)
mtext("Education was associated with lower unemployment at every age.",
      side = 3, outer = TRUE, line = -1, cex = 1.3, font = 2)
dev.off()
