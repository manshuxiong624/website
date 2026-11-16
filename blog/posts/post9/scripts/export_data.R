# Run from the post9 directory. R's datasets package is the authoritative input.
data("EuStockMarkets", package = "datasets")
dir.create("data", showWarnings = FALSE)
write.csv(data.frame(observation = seq_len(nrow(EuStockMarkets)),
                     as.data.frame(EuStockMarkets)),
          "data/european_indices.csv", row.names = FALSE)
