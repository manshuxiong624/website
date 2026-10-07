# Blog Post 4: Citi Bike in January

This folder contains the Quarto article and the complete analysis pipeline for a descriptive look at January 2024 Citi Bike trips. It compares weekday and weekend trip-start patterns and trip duration by rider type.

## Reproduce the published post

Use R 4.1 or newer and an RStudio installation with Quarto available. The derived CSV files and SVG figures are included in the repository. A normal website render uses those files; it does **not** download the large raw archive.

1. Open the website project in RStudio (the folder containing `_quarto.yml`).
2. Install the required R packages once, if they are not already installed:

   ```r
   install.packages(c("dplyr", "readr", "tidyr", "lubridate", "tibble", "ggplot2", "knitr"))
   ```

3. Open `blog/posts/post4/BlogPost4.qmd` and click **Render** to render only this article, or select **Build → Render Website** to rebuild the site into `docs/`.

The post reads the committed summary tables and regenerates its figures from the committed analysis tables. It stops with a clear message if any required derived table is missing.

## Rebuild from Citi Bike's raw data

Run these lines in the RStudio Console while the website project is open:

```r
source("blog/posts/post4/blogpost4_citibike.R")
source("blog/posts/post4/make_figures.R")
```

The analysis script downloads the January 2024 archive on its first run (approximately 352 MB), validates the ZIP before saving it, and reads every CSV member in sorted order. Later runs reuse the local archive at `blog/posts/post4/data/raw/202401-citibike-tripdata.zip`. It then overwrites the derived tables and writes source and environment details. The figure script recreates the three SVGs. Finally, render the post or website as described above.

If the download is interrupted, its temporary file is discarded and the final ZIP is not replaced by a partial file. If an existing ZIP is corrupt, move it out of `data/raw/` and rerun the analysis script to download a fresh copy.

## Project files

- `BlogPost4.qmd` — article, using the saved summary tables and figures
- `blogpost4_citibike.R` — downloads and processes the official trip archive
- `make_figures.R` — creates the three figures from derived tables
- `data/raw/` — local raw archive; intentionally excluded from Git
- `data/derived/` — generated CSV summaries, source metadata, and R session details
- `images/` — generated SVG figures used in the article

Key outputs in `data/derived/`:

- `daily_rides.csv` — daily ride counts and weekday/weekend labels
- `hourly_by_day_type.csv` — mean rides per clock hour and day type
- `weekday_hour_mean.csv` — mean rides per weekday and hour
- `duration_histogram.csv` — five-minute duration-bin shares by rider type
- `duration_median_bins.csv` — approximate median duration-bin centers
- `summary_stats.csv` — values used in the article text
- `source_metadata.csv` — source URL, row counts, and (after a full rebuild) archive checksum, R/platform, and direct package versions
- `session_info.txt` — R version, platform, and loaded-package details; refreshed by a full data rebuild

## Data, definitions, and checks

- Source landing page: <https://citibikenyc.com/system-data>
- January 2024 archive: <https://s3.amazonaws.com/tripdata/202401-citibike-tripdata.zip>
- Data-sharing policy: <https://citibikenyc.com/data-sharing-policy>
- Scope: trips starting in January 2024; timestamps interpreted in `America/New_York`
- Day groups: Monday–Friday (`Weekday`) and Saturday–Sunday (`Weekend`)
- Hourly averages: trip starts per calendar day in each group, so groups with different numbers of days are comparable
- Duration sample: valid trips from 1 minute to less than 120 minutes, summarized in five-minute bins

For the committed January 2024 extract, the analysis produced **1,887,675 valid rides** and excluded **410 rows** for invalid or out-of-scope records. Compare these counts with `summary_stats.csv` and `source_metadata.csv` after a full rebuild. Each full data rebuild records the raw archive's MD5 checksum, the R version, platform, direct package versions, CSV members processed, and `session_info.txt`. The currently committed metadata predates the checksum fields; run the two scripts above to refresh it. Package versions are recorded for each rebuild, but this folder does not yet pin packages with a lockfile. No random seed is needed because the pipeline uses deterministic filtering, aggregation, and plotting.

The raw archive is not committed because Citi Bike's data-sharing policy restricts redistribution of the source files. The code downloads it from the official source when needed; the derived summaries and scripts are included here so the analysis can be inspected and reproduced.
