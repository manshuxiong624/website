# Blog Post 3: Education and unemployment in the U.S.

This project reproduces the figures and weighted descriptive statistics used in the Blog Post 3 analysis, **“Education and Unemployment in the U.S.: Who Bore the COVID-19 Shock?”**

## Research question

How did unemployment differ by educational attainment before, during, and after the COVID-19 labor-market shock?

The analysis describes adults ages 25--64 who were in the civilian labor force. It is descriptive, not causal.

## Data source

Download the data from [IPUMS CPS](https://cps.ipums.org/).

Select:

- Samples: **Basic Monthly**, every month from **2015 through 2024**; do not select ASEC.
- Variables: `YEAR`, `MONTH`, `AGE`, `SEX`, `EMPSTAT`, `EDUC`, and `WTFINL`.
- Format: **Comma delimited (.csv)**.
- Structure: **Cross-sectional → Rectangular → person**.

Save the downloaded file as `cps_00003.csv` in the `data/` folder. The raw data are not included in this repository because the extract is large. The file is excluded by `.gitignore` and must not be committed.

Alternatively, set the `CPS_DATA_PATH` environment variable to the CSV's full path before running the script; this is useful when the raw extract is stored outside the project folder.

## Reproduce the analysis

1. Open `BlogPost3.Rproj` in RStudio.
2. Confirm that `data/cps_00003.csv` exists.
3. Open `blogpost3_cps_csv.R` and run the full script.
4. Open `BlogPost3.md` for the final post, or copy it into the Quarto website post.

The scripts use **base R only** and require R 4.1.0 or newer. No external R packages are needed.

The main script validates the required columns and expected 2015--2024 sample years before producing any result. Each run writes a record in `real_results/analysis_manifest.txt` and a full R session record in `real_results/session_info.txt`.

## Definitions

| Item | Definition |
|---|---|
| Population | Civilian labor-force participants ages 25--64 |
| Labor force | `EMPSTAT` codes 10, 12, 21, and 22 |
| Unemployed | `EMPSTAT` codes 21 and 22 |
| Unemployment rate | Weighted unemployed people divided by the weighted civilian labor force |
| Weight | `WTFINL`, IPUMS CPS Final Basic Weight |
| Education groups | Less than high school; high school; some college/associate; bachelor's; graduate degree |

IPUMS documents `WTFINL` as the appropriate final person-level weight for Basic Monthly CPS analysis: [IPUMS CPS weight documentation](https://cps.ipums.org/cps-action/variables/WTFINL).

## Files

| File | Purpose |
|---|---|
| `blogpost3_cps_csv.R` | Imports and validates the CPS CSV, creates weighted tables, and writes run metadata |
| `make_figures.R` | Creates the three PNG figures from the summary tables |
| `BlogPost3.md` | Finished blog-post text |
| `real_results/` | Generated tables, figures, manifest, and session information |
| `data/` | Location for the downloaded IPUMS CSV; intentionally excluded from Git |

## Outputs

Running the script recreates:

- `real_results/annual_unemployment_by_education.csv`
- `real_results/annual_unemployment_by_age_and_education.csv`
- `real_results/headline_results_table.csv`
- `real_results/figures/figure_1_education_trends.png`
- `real_results/figures/figure_2_pandemic_comparison.png`
- `real_results/figures/figure_3_age_education_trends.png`

## Version-control note

Commit the code, README, blog text, summary tables, and figures. Do **not** commit the IPUMS source extract. This keeps the repository compact while allowing anyone with an IPUMS account to recreate the results from the documented extract specification.
