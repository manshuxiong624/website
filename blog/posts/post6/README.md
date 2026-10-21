# Blog Post 6: Matching Parents and Children with SQL in Python

This project is a complete, reproducible tutorial for matching two generations in longitudinal income data and estimating an intergenerational income elasticity (IGE).

## What it demonstrates

- A person-level file with stable `person_id` and `family_id` identifiers.
- A family roster that identifies parents and children within each family.
- SQLite queries run from Python using `SELECT`, `JOIN`, `GROUP BY`, conditional aggregation, and log-income transformations.
- Single-year IGE estimates at ages 25, 30, and 35 compared with five-year average income at ages 35–39.
- Reproducible tables, a SQLite database, and two SVG figures.

**Data note:** The project generates a simulated panel with 5,000 parent–child pairs. It is designed to make the matching and life-cycle measurement issue easy to inspect, and it does not use or claim to represent PSID or other survey respondents. The simulated long-run IGE is set to 0.40; the estimated values vary because observed annual earnings include noise and the sample is finite.

## Requirements

Python 3.9 or newer. The analysis uses only Python's standard library, so no package installation or internet connection is needed. `requirements.txt` is intentionally empty of third-party packages.

## Run the analysis

From this project directory, run:

```bash
python3 src/run_analysis.py
```

The fixed random seed (`20261021`) makes the generated inputs and results reproducible. Running the script again overwrites the generated CSV files, SQLite database, result tables, and figures.

## Project layout

```text
blogpost6_parent_child_ige/
├── README.md
├── blogpost6.qmd                  # Tutorial article for a Quarto blog
├── requirements.txt               # Standard library only
├── data/
│   ├── README.md
│   ├── family_members.csv          # Person-to-family links and roles
│   └── income_panel.csv            # Person-year income and age records
├── sql/
│   └── parent_child_ige.sql        # SQL CTEs, joins, and aggregations
├── src/
│   └── run_analysis.py             # Data generation, SQLite execution, OLS, figures
└── outputs/
    ├── ige_estimates.csv
    ├── matched_parent_child.csv
    ├── matched_sample_preview.csv
    ├── parent_child_panel.sqlite
    └── figures/
        ├── ige_lifecycle_comparison.svg
        └── ige_long_run_scatter.svg
```

## Reproducing the blog figures

The script saves figures to `outputs/figures/`. The Quarto article references them directly. If you copy `blogpost6.qmd` into an existing Quarto website, copy the `outputs/figures/` directory alongside it or update the image paths. From a Quarto installation, render with:

```bash
quarto render blogpost6.qmd
```

The SQL query uses SQLite's `LOG()` and `EXP()` functions, registered by `run_analysis.py` with Python's `math` module. The script creates both tables and registers those functions before executing the query.

## Adapt to real longitudinal data

For an empirical project, replace `generate_panel()` with a documented import step for the approved dataset. Preserve stable person and family identifiers, check whether family identifiers refer to the correct generation and survey wave, document income units and years, apply the dataset's weights if estimating population-representative statistics, and define rules for missing, zero, or negative income before taking logs. Do not infer parent-child links from similar names or household membership alone; use the dataset's documented relationship codes and longitudinal identifiers.
