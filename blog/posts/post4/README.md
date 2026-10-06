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

Then open `BlogPost4.qmd` in RStudio and click **Render**. The article uses the included derived CSV files and existing SVG figures, so rendering the website does not redownload the 352 MB raw archive. To regenerate the complete website, use **Build → Render Website** from the website project.

To update the data and figures from the website project root, run:

```r
source("blog/posts/post4/blogpost4_citibike.R")
source("blog/posts/post4/make_figures.R")
```

The data script downloads the official archive if it is not present. Afterward, render the post or the whole website. To render from the RStudio Terminal in the `post4` folder, run:

```sh
quarto render BlogPost4.qmd
```

The article reads summary statistics from the committed derived tables and rebuilds figures from those tables. This keeps routine website builds quick and avoids network downloads. Run the data script explicitly when you want to refresh the data; it reads every CSV in the January archive and writes updated derived tables.

## Data and definitions

- Official source page: <https://citibikenyc.com/system-data>
- January 2024 archive: <https://s3.amazonaws.com/tripdata/202401-citibike-tripdata.zip>
- Data-sharing policy: <https://citibikenyc.com/data-sharing-policy>
- Scope: records with trip start dates in January 2024
- Day groups: Monday–Friday (`Weekday`), Saturday–Sunday (`Weekend`)
- Timing averages: ride starts per actual calendar date in each group
- Duration comparison: valid trips from 1 minute to less than 120 minutes; five-minute bins

Citi Bike notes that its published data omit trips under 60 seconds and staff/test trips, and that busy months may be split across multiple CSV files. The script reads all CSV members in the month archive. The data-sharing policy allows use in noncommercial analyses and reports but restricts stand-alone dataset distribution. The raw archive is therefore downloaded locally by the script rather than included in this folder.
