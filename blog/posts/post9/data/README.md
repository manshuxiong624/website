# Data source and timing

`european_indices.csv` is an unmodified numeric export of R's built-in
`datasets::EuStockMarkets`, with an observation-number column added.
There are 1,860 observations for DAX, SMI, CAC, and FTSE, covering 1991–1998.
The R documentation credits Erste Bank AG, Vienna, Austria.

Official documentation:
https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/EuStockMarkets.html

These are historical index closing levels, not individual-stock observations.
R supplies a business-time series, not exact daily calendar dates. We retain
observation order and never fabricate dates or assign exact split years.
Different exchanges need not have identical holiday or closing schedules.
The full-observation execution delay mitigates timing problems, but cannot
establish synchronized, executable quotes. Results are an educational proxy.
The dataset is not documented as a consistently comparable total-return series
across markets. FTSE changes are treated as price returns; we do not add dividends.

Recreate the CSV from the post9 directory with:

```r
source("scripts/export_data.R")
```

All predictors use observations through t. The target is
`FTSE[t+2] / FTSE[t+1] - 1`. A signal formed after t is hypothetically executed
at t+1's close. The two feature rows before each later split are purged so
training target observations precede validation/test feature observations.
Raw rows 1–20 provide feature history; the final two cannot supply a target.
