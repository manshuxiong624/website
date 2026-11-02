# Blog Post 8 — Simulation and Statistical Inference

This folder contains a reproducible Quarto post about percentile bootstrap confidence intervals, long-run confidence-interval coverage, and hypothesis testing under a simulated null hypothesis.

## Folder contents

- `blogpost8.qmd` — article, analysis code, and three interactive Plotly visualizations.
- `scripts/simulation_helpers.R` — reusable bootstrap and simulation functions.
- `results/` — CSV summaries and interval-level output generated when the article is rendered. These results are created by the code, not copied into the article by hand.
- `data/README.md` — explains why no external data file is needed.

## Requirements

Install R and Quarto, then install the R packages used by the article:

```r
install.packages(c("plotly", "knitr"))
```

The observations are generated with base R and fixed random seeds. Rendering does not call an API or download a dataset.

## Render in RStudio and add to the website

1. Unzip this folder.
2. Copy the entire `post8` folder into the existing website at `blog/posts/post8/`, next to `post7`.
3. Open the website project in RStudio (the folder that contains `_quarto.yml`).
4. Render the full website with **Render** in RStudio or run this in the Console:

   ```r
   quarto::quarto_render()
   ```

   To render only this post from the website root:

   ```bash
   quarto render blog/posts/post8/blogpost8.qmd
   ```

The post uses the site's `_quarto.yml` for its navigation and output directory. Keep the source folder in the repository; Quarto generates the HTML output as configured by the site. Commit the new `blog/posts/post8/` folder and the generated website output only if that is how the existing repository publishes its pages. Push the changes to GitHub, then check the published site after the Pages build finishes.

If rendering from this folder by itself rather than from the website project, run `quarto render blogpost8.qmd` here. The `results/` CSV files are generated during rendering.

## Reproducibility notes

The seeds and simulation settings are declared near the top of `blogpost8.qmd`. Change `sample_size`, `coverage_sample_size`, `bootstrap_reps`, `coverage_reps`, `coverage_bootstrap_reps`, `null_reps`, or `confidence_levels` to explore how results change, then render again. The code writes:

- `results/coverage_summary.csv` — empirical coverage by confidence level;
- `results/coverage_intervals.csv` — every simulated confidence interval and whether it covered the true mean;
- `results/null_test_summary.csv` — observed statistic, critical value, and simulated p-value.

The analysis uses a known normal population so the true mean is available for checking coverage. This is an instructional simulation, not an analysis of real-world outcomes.
