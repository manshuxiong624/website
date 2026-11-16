# Blog Post 9 — Predicting Stock Returns with Gradient Boosting

## 先看这里

解压后，把 **整个 `post9` 文件夹**放进原网站的 `blog/posts/` 里，与 `post8` 并列。
正文是 `blogpost9.qmd`，不是 Rmd。也附上已经渲染好的 `blogpost9.html`，
双击即可先看完整文章；HTML 内嵌图片，查看时不需要安装 Python。

不要用这个文件夹覆盖原网站，不要覆盖 `_quarto.yml`、`index.qmd` 或旧帖子。
`post9.Rproj` 方便单独打开和测试；发布时请打开**原网站的 RStudio 项目**。

## What this project does

1. Reproduces the supplied Class 21 simulated gradient-boosting example.
2. Applies the same scikit-learn settings to real historical FTSE index returns.
3. Attempts an improvement with richer momentum/volatility/cross-market features
   and validation-only hyperparameter selection.
4. Compares both models with a fixed historical-mean forecast on a chronological test set.
5. Evaluates a prespecified long-or-cash rule after turnover costs, with buy-and-hold.

**Scope limitation:** the supplied Class 21 QMD contains a simulated prediction
exercise, not a stock-prediction experiment. The baseline here transfers its
algorithm settings to stocks; it is not a reconstruction of an unavailable stock
experiment. The post states this explicitly. This satisfies the executable
comparison and improvement components, but an instructor who requires the exact
in-class stock experiment may require its separate data/code before submission.
The real data are stock **indices**, not individual securities, from 1991–1998.

## Folder contents

| Path | Purpose |
|---|---|
| `blogpost9.qmd` | Complete English article with dynamically generated results |
| `blogpost9.html` | Rendered, self-contained article preview |
| `post9.Rproj` | Optional standalone RStudio project |
| `requirements.txt` | Python versions used for the supplied results |
| `data/european_indices.csv` | Included offline raw data |
| `data/README.md` | Official source, data definitions, and timing limitations |
| `scripts/analysis.py` | Full simulation, feature engineering, tuning, prediction, backtest |
| `scripts/run_analysis.R` | Finds a Python environment and runs analysis during render |
| `scripts/export_data.R` | Recreates raw CSV from R's built-in dataset |
| `results/` | Generated CSV tables, predictions, software versions, and figures |

## One-time setup in RStudio

R and Quarto are required. Recent RStudio versions include Quarto. In the **R Console**:

```r
install.packages("knitr")
```

If your existing course Python environment already has NumPy, pandas,
scikit-learn and matplotlib, the render script will discover it automatically.
The code uses Python for exactly the same estimator as the supplied lesson;
R handles Quarto rendering. No reticulate, API key, or live data connection is needed.

Otherwise open **Terminal** in RStudio with the working directory set to `post9`.
For macOS/Linux, with Python 3.10–3.12 installed:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

For Windows:

```powershell
py -3.12 -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

The pinned NumPy version predates Python 3.13. If your default Python is 3.13,
use a Python 3.12 interpreter or the course environment. Newer package releases
may also work but can change results slightly. `results/summary.json` records
the versions actually used each time the post renders.

For a custom environment, set this in the **R Console** before rendering:

```r
Sys.setenv(POST9_PYTHON = "/absolute/path/to/python")
```

When using an external Terminal render, set the same environment variable in
that Terminal; R Console environment changes only apply to that R session.

## Render and publish through the existing website

1. Copy the entire folder into `blog/posts/post9/` beside `post8`.
2. Open the original website's RStudio project (the root containing `_quarto.yml`).
3. Open `blog/posts/post9/blogpost9.qmd` and click **Render**.
4. Render the full website from the project root in RStudio's **Terminal**:

   ```bash
   quarto render
   ```

5. Preview the website and check that Post 9 appears on its blog listing page.
   If the listing has `contents: posts` or `contents: posts/*/*.qmd` relative
   to the blog directory, it normally discovers this post automatically. If the
   site manually lists posts, add a link to `posts/post9/blogpost9.qmd` from
   `blog/index.qmd` (or the appropriate relative path from the actual listing).
   If `project.render` is an explicit file list, add the new QMD there too.
6. In the RStudio Git pane, stage the new post and the output files required
   by the website's existing publishing configuration; **Commit → Push**.
   For a Pages site publishing `/docs`, commit updated `docs/` output. For a
   GitHub Actions rendering workflow, follow that workflow's source/output rules.
   `_site/` output is not automatically published just because it exists locally.
7. Wait for GitHub Pages deployment and verify the public article URL.

To render only this post from the website root:

```bash
quarto render blog/posts/post9/blogpost9.qmd
```

The package intentionally has **no nested `_quarto.yml`**, so the post inherits
your website's navigation and output directory. `execute-dir: project` in an
existing site would change relative paths; use Quarto's default file-relative
execution directory for this post. Do not upload `.venv` or `.Rproj.user`.

The assignment asks for **both the published article URL and the GitHub
repository URL**. This package does not push or publish on your behalf.

## Reproduce without Quarto

From the post9 directory, use your configured Python:

```bash
python scripts/analysis.py
```

All results are regenerated from the included CSV. Seeds are fixed at 6400.
With the supplied versions the baseline test RMSE is about 1.022 percentage
points, tuned RMSE 0.996, historical-mean RMSE 0.990. The tuned model is always
long in the test block and therefore matches buy-and-hold after matching costs.
The code does not force those outcomes and the article reads the generated files.

## Evaluation details

- Features: observations through t only; target: FTSE[t+2]/FTSE[t+1] - 1.
- Chronological 60/20/20 allocation with two boundary rows purged.
- Both final fitted models use the same pre-test refitting sample.
- Hyperparameters chosen from 16 configurations using validation MSE.
- One untouched test window; no test-driven model reselection.
- RMSE, MAE, sign accuracy, and R2 against a fixed pre-test historical mean.
- Economic rule fixed at forecast > 0, otherwise cash; no fitted trading threshold.
- 10 bp one-way turnover costs, including entry and final exit; zero cash return.
- Supplemental cost sensitivity at 0, 5, 10 and 25 bp for the tuned model.
- Annualization in saved metrics assumes 252 observations per year; Sharpe uses zero cash.
- Price/index returns are illustrative; no claim of executable, dividend-adjusted alpha.

Data source: https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/EuStockMarkets.html

Method: https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingRegressor.html

Course reference: Yisroel Cahn, Class 21 QMD, sections 3–4 and 50, supplied by the user.
