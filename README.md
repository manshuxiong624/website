# Manshu Xiong's Quarto Website

This repository contains the source files for my course website and blog posts. The live site is built with Quarto; rendered files are committed in `docs/` so GitHub Pages can publish them.

## Repository map

| Location | Purpose |
|---|---|
| `_quarto.yml` | Website configuration, navigation, and the `docs/` publishing folder |
| `index.qmd`, `about.qmd`, `bio.qmd`, `resume.qmd` | Main website pages |
| `blog/` | Blog listing and individual blog-post source folders |
| `blog/posts/post2/` | **Blog Post 2:** Philadelphia apartment-rent analysis, code, data, figures, and reproduction instructions |
| `docs/` | Rendered website published by GitHub Pages; do not edit by hand |
| `images/` | Images used by the main website pages |

## Blog Post 2: Philadelphia apartment rents

The post asks where a renter with a $1,500 monthly base-rent budget should begin looking among a sample of Philadelphia apartment properties. The written post is in [`blog/posts/post2/index.qmd`](blog/posts/post2/index.qmd). Its complete guide is in [`blog/posts/post2/README.md`](blog/posts/post2/README.md).

The post's supporting files are organized as follows:

| Location | Contents |
|---|---|
| `blog/posts/post2/R/01_scrape.R` | Reads the saved HTML snapshots with `rvest`; optional live collection is available only with `--live` |
| `blog/posts/post2/R/02_analyze.R` | Cleans records, creates the comparison tables, and generates both figures |
| `blog/posts/post2/data/` | Source manifest, saved table-only HTML snapshots, raw data, cleaned data, and analysis outputs |
| `blog/posts/post2/figures/` | Generated figures used by the post |
| `blog/posts/post2/setup.R` | Installs any required R packages in a local project library |
| `blog/posts/post2/run.R` | Reproduces the saved-snapshot analysis in one command |

## Reproduce Blog Post 2

Open R or RStudio with the working directory set to `blog/posts/post2/`, then run:

```r
source("run.R")
```

The first run installs missing packages into `blog/posts/post2/.R-library/`. The default workflow reads the saved snapshots, so it reproduces the analysis without making new requests to the rental website. It regenerates the cleaned CSV files and both figures in `figures/`.

## Build the website

From the repository root, run:

```bash
quarto render
```

Quarto writes the published website to `docs/`. After changing source files, commit both the source changes and the updated `docs/` output.
