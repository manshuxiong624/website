# Blog Post 4 — Citi Bike

This folder follows the same layout as the earlier blog-post folders: the Quarto article, two R scripts, a `data/` directory, figures in `images/`, and this README.

## Folder contents

- `BlogPost4.qmd` — the finished blog article, formatted for a Quarto website with a right-side table of contents
- `blogpost4_citibike.R` — downloads/reads the official trip archive and creates analysis tables
- `make_figures.R` — rebuilds the three SVG figures from the derived tables
- `data/raw/` — raw source archive downloads here on the first run; large source files are ignored by Git
- `data/derived/` — processed ride tables and source metadata
- `images/` — the three figures used by the article

## Run in RStudio / Quarto

Use R 4.1 or newer. Install these packages once if needed:

```r
install.packages(c("dplyr", "readr", "tidyr", "lubridate", "tibble", "ggplot2", "knitr"))
```

To rebuild the data and figures from the `post4` folder:

```r
source("blogpost4_citibike.R")
source("make_figures.R")
```

Then open `BlogPost4.qmd` in RStudio and click **Render**, or run this in the RStudio Terminal from the `post4` folder:

```sh
quarto render BlogPost4.qmd
```

The article sources both scripts when it renders, so its summary numbers and figures update with the derived data. If the January 2024 raw archive is not present, the analysis script downloads it automatically. The archive is approximately 352 MB, so the first run can take a few minutes.

## Data and definitions

- Official source page: <https://citibikenyc.com/system-data>
- January 2024 archive: <https://s3.amazonaws.com/tripdata/202401-citibike-tripdata.zip>
- Data-sharing policy: <https://citibikenyc.com/data-sharing-policy>
- Scope: records with trip start dates in January 2024
- Day groups: Monday–Friday (`Weekday`), Saturday–Sunday (`Weekend`)
- Timing averages: ride starts per actual calendar date in each group
- Duration comparison: valid trips from 1 minute to less than 120 minutes; five-minute bins

Citi Bike notes that its published data omit trips under 60 seconds and staff/test trips, and that busy months may be split across multiple CSV files. The script reads all CSV members in the month archive. The data-sharing policy allows use in noncommercial analyses and reports but restricts stand-alone dataset distribution. The raw archive is therefore downloaded locally by the script rather than included in this folder.
