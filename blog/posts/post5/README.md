# Blog Post 5 — Quarto website folder

This is the single folder to place in your existing Quarto website:

```text
website/
└── blog/
    └── posts/
        └── post5/          <- copy this folder here
            ├── blog_post5.qmd
            ├── R/prepare_data.R
            └── data/processed/
```

Your website root is the directory containing `_quarto.yml` (the screenshot shows it uses `project: type: website` and `output-dir: docs`). Do **not** open a separate `.Rproj` inside `post5`; open the existing website project so it uses the website's settings and theme.

## Run and preview

Install the required R packages once:

```r
install.packages(c("sf", "dplyr", "readr", "jsonlite", "ggplot2", "scales"))
```

From a terminal at the website root, preview just this post:

```sh
quarto preview blog/posts/post5/blog_post5.qmd
```

Or render the full website:

```sh
quarto render
```

On the first run, the post downloads 2024 ACS county estimates from the Census API and 2024 TIGER/Line county boundaries. It saves the cleaned CSV and joined GeoPackage into this folder's `data/processed/` directory, then renders the post using the root website's Quarto configuration. Quarto runs the document's code from the document directory by default, so the relative paths in this folder work when previewed from the website root.

## Publish

After rendering successfully, commit the whole `blog/posts/post5/` folder and the site's generated `docs/` changes using the existing website workflow, then push to the same GitHub branch used for the site. If `blog/index.qmd` maintains a manual list of posts, add a link to `posts/post5/blog_post5.qmd` there. The output page will be under `docs/blog/posts/post5/blog_post5.html` unless the site changes its output structure.

## Data

- Income: U.S. Census Bureau, 2024 ACS 5-year estimates, table B19013 (median household income in 2024 inflation-adjusted dollars).
- Boundaries: U.S. Census Bureau, 2024 TIGER/Line county shapefiles.
- The comparison covers Bucks, Chester, Delaware, Montgomery, and Philadelphia counties in Pennsylvania; Burlington, Camden, Gloucester, and Salem counties in New Jersey; and New Castle County in Delaware. These county medians describe a geographic pattern; they do not show within-county inequality or establish why incomes differ.

Sources: [ACS table B19013](https://data.census.gov/table/ACSDT5Y2024.B19013) · [Census API metadata](https://api.census.gov/data/2024/acs/acs5/variables/B19013_001E.html) · [2024 TIGER/Line files](https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.2024.html)
