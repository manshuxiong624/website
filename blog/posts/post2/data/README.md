# Data guide

This folder separates the saved inputs from the outputs created by the analysis.

## Inputs retained from the collection

| File or folder | Purpose |
|---|---|
| `sources.csv` | One row per property page, including source URL, snapshot path, and collection timestamp |
| `snapshots/` | Table-only HTML extracts used by `rvest`; each contains the property name, location heading, and floor-plan table |
| `robots-reviewed.txt` | The public `robots.txt` text reviewed on the collection date |
| `directory_links.html` | The source-directory property links used to define the collection scope |

## Outputs created by the scripts

| File | Created by | Purpose |
|---|---|---|
| `floorplans_raw.csv` | `R/01_scrape.R` | The 59 extracted floor-plan rows, retaining rent and area text exactly as published |
| `floorplans_clean.csv` | `R/02_analyze.R` | Parsed variables, area grouping, eligibility flag, and reason for exclusion |
| `one_bedroom_comparison.csv` | `R/02_analyze.R` | The 16 standard one-bedroom, one-bathroom layouts with numerical starting rents |
| `area_summary.csv` | `R/02_analyze.R` | Area-level descriptive summary used in the post table |
| `exclusions.csv` | `R/02_analyze.R` | Count of records removed by each cleaning rule |
| `sessionInfo.txt` | `R/02_analyze.R` | R and package versions used to create the saved outputs |

`blog_input_checksums.csv` and `blog_word_count.txt` support the earlier standalone HTML version of the post. They do not affect the Quarto website render or the analytical results.
