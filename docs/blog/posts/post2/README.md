# Blog Post 2: What Can $1,500 Rent in Philadelphia?

This folder contains every source file needed to reproduce the analysis and render the Blog Post 2 page in the course website.

## Research question

Among the Philadelphia properties listed by Galman Group, where should a renter with a **$1,500 monthly base-rent budget** begin looking for a standard one-bedroom apartment?

The post compares advertised starting rent and, when a single floor-plan size is provided, starting rent per square foot. It makes a recommendation for a renter's first inquiries; it does not claim to estimate rent for all Philadelphia apartments.

## Start here

| File or folder | What it is |
|---|---|
| [`index.qmd`](index.qmd) | The published blog-post source: narrative, table, figures, sources, and visible code appendix |
| [`run.R`](run.R) | One-command entry point to reproduce the analysis from saved snapshots |
| [`R/01_scrape.R`](R/01_scrape.R) | Imports the saved HTML snapshots with `rvest`; it can optionally collect fresh public data |
| [`R/02_analyze.R`](R/02_analyze.R) | Cleaning rules, eligibility criteria, summaries, and figure creation |
| [`data/`](data/) | Input snapshots, source manifest, raw records, cleaned data, and generated analysis tables |
| [`figures/`](figures/) | The two generated PNG figures embedded in `index.qmd` |
| [`setup.R`](setup.R) | Installs the packages required to run the analysis |

## Reproduce the analysis

### Requirements

- R 4.1 or later
- An internet connection only the first time packages are installed

### Steps

1. Open an R session with this `post2` folder as the working directory.
2. Run:

   ```r
   source("run.R")
   ```

3. The script installs any missing packages into `.R-library/`, reads the saved factual HTML extracts in `data/snapshots/`, and regenerates:

   - `data/floorplans_raw.csv`
   - `data/floorplans_clean.csv`
   - `data/one_bedroom_comparison.csv`
   - `data/area_summary.csv`
   - `data/exclusions.csv`
   - `figures/starting_rents.png`
   - `figures/rent_per_sqft.png`

4. From the website root, run `quarto render` to rebuild the published blog post in `docs/blog/posts/post2/`.

The default workflow is intentionally offline after packages are installed: it reads the saved HTML table extracts rather than requesting the rental website again. The collection date and R package information are recorded in `data/sources.csv` and `data/sessionInfo.txt`.

## Data and cleaning decisions

The source directory was the [Galman Group Philadelphia property directory](https://galmangroup.com/philadelphia/). On September 21, 2026, the project recorded 21 Philadelphia property pages and 59 floor-plan records.

The analysis keeps standard one-bedroom, one-bathroom layouts with a published numerical starting rent. It excludes 34 records with another bedroom count, five junior, den, or bi-level layouts, and four eligible layouts whose rent was listed as “Call for Availability.” The resulting comparison sample has 16 floor plans at 16 properties. `data/exclusions.csv` records this audit trail.

Locations are assigned from each property page’s location heading. Fox Chase, Somerton, Bustleton, and Rhawnhurst are grouped as Northeast Philadelphia. This grouping supports a descriptive comparison only; the sample is from one property manager and is not a citywide market estimate.

## Ethical and technical collection

The data were collected from public static pages only. The collection checked the public `robots.txt`, used sequential requests with a two-second pause, and did not access login, application, resident, or CAPTCHA pages. Saved snapshots retain only each property’s name, location heading, and floor-plan table, which keeps the repository small and makes the analysis reproducible.

`R/01_scrape.R --live` can request a fresh snapshot, but it first compares the current `robots.txt` with the reviewed version and stops if it changed. A refreshed collection may change the results, so the narrative and figures must be reviewed before publication.

## Expected results

The saved analysis identifies Roxborough as the area with the lowest median advertised starting rent among the areas with at least four comparable properties: **$1,310 per month**. Four of its five sampled properties were at or below the $1,500 base-rent threshold. The figures and post discuss the limits of that conclusion, including unequal sample sizes, unobserved fees, and lack of vacancy verification.
