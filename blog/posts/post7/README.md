# Blog Post 7 — Interactive Data Visualization with Plotly

This folder contains the complete Quarto source for Post 7. The article studies the relationship between GDP per capita and life expectancy using the `gapminder` dataset, with an animated Plotly scatterplot, a country trend chart, and a continent comparison.

## Reproduce the article

The dataset is included in the `gapminder` R package. Rendering does not call the World Bank API or download a separate data file. Install the packages once in RStudio:

```r
install.packages(c("gapminder", "dplyr", "plotly", "knitr"))
```

Copy `blogpost7.qmd` into the website project at `blog/posts/post7/blogpost7.qmd`. Keep the website's existing `_quarto.yml` and render from the website root:

```bash
quarto render
```

To render only this post from the website root:

```bash
quarto render blog/posts/post7/blogpost7.qmd
```

The website configuration controls where the rendered HTML is written. Commit the `.qmd` source to the same GitHub repository as the website so the analysis can be reproduced. Move any older `blogpost7.Rmd` version out of the website source folder to avoid duplicate versions of the post.

## Data and limitations

The article uses 1,704 observations covering 142 countries and 12 five-year-spaced observations from 1952 through 2007. GDP per capita, life expectancy, population, and continent are documented in the article. The analysis is descriptive and does not show that income causes longer life expectancy.
