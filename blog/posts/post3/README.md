# Blog Post 3: Education and unemployment

This Quarto post analyzes unemployment by educational attainment using IPUMS CPS Basic Monthly data from 2015–2024. It covers adults ages 25–64 in the civilian labor force and uses `WTFINL`, the CPS Final Basic Monthly person weight.

## Restore this post to the website

This folder must be located at `website/blog/posts/post3/`. The webpage file must be named `index.qmd`; a file named `BlogPost3.md` is not rendered automatically as a Quarto post.

Open the website project in RStudio and select **Render**. This creates the updated webpage and copies its figures into `docs/`. Then use the Git pane to commit the changed `blog/posts/post3/` and `docs/` files, followed by Push.

## Reproduce the analysis

In IPUMS CPS, select Basic Monthly samples for 2015–2024 (not ASEC), person-level rectangular CSV format, and variables `YEAR`, `AGE`, `EMPSTAT`, `EDUC`, and `WTFINL`. Save the downloaded CSV as `data/cps_00003.csv`. It is excluded from Git because it is large.

Run `source("blogpost3_cps_csv.R")` from this folder. The script creates the weighted annual result table and all three PNG figures. `make_figures.R` can also recreate the figures from the saved summary table alone.

Unemployed persons have `EMPSTAT` codes 21 or 22. The civilian labor force includes codes 10, 12, 21, and 22. Results are weighted annual averages of monthly CPS interviews, not unique-person annual estimates.
