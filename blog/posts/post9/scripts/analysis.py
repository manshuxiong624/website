"""Chronological stock-index prediction experiment. Run from any directory."""
from pathlib import Path
import os
import tempfile
os.environ.setdefault("MPLCONFIGDIR", str(Path(tempfile.gettempdir()) / "post9_matplotlib"))
import json
import platform
import numpy as np
import pandas as pd
import sklearn
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error
from sklearn.model_selection import train_test_split, ParameterGrid

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results"
FIG = OUT / "figures"
FIG.mkdir(parents=True, exist_ok=True)
plt.rcParams.update({"figure.dpi": 140, "axes.spines.top": False,
                     "axes.spines.right": False, "font.size": 10})
SEED = 6400
CLASS_PARAMS = dict(n_estimators=300, learning_rate=0.05, max_depth=2,
                    min_samples_leaf=5, random_state=SEED)

def savefig(name):
    plt.tight_layout()
    plt.savefig(FIG / name, bbox_inches="tight")
    plt.close()

def reproduce_class_simulation():
    # Class 21 sections 3-4 and 50, with the same random-number generator.
    rng = np.random.default_rng(SEED)
    x = rng.normal(size=(1200, 5))
    y = (3 + 2*x[:, 0] - 4*(x[:, 0] > 0) + 3*(x[:, 1] > 1)
         + 2*x[:, 0]*x[:, 1] + rng.normal(scale=1.5, size=1200))
    xt, xv, yt, yv = train_test_split(x, y, test_size=0.25, random_state=SEED)
    model = GradientBoostingRegressor(**CLASS_PARAMS).fit(xt, yt)
    pred = model.predict(xv)
    rows = [{"model": "Training mean", "test_mse": mean_squared_error(yv, np.full(len(yv), yt.mean()))},
            {"model": "Class 21 boosting", "test_mse": mean_squared_error(yv, pred)}]
    pd.DataFrame(rows).to_csv(OUT / "class_simulation.csv", index=False)
    return rows

def make_data():
    prices = pd.read_csv(ROOT / "data/european_indices.csv")
    assert len(prices) == 1860 and prices.observation.is_unique
    markets = ["DAX", "SMI", "CAC", "FTSE"]
    assert prices[markets].gt(0).all().all()
    # Ordinary fractional returns. No fabricated calendar dates.
    ret = prices[markets].pct_change(fill_method=None)
    d = pd.DataFrame({"feature_observation": prices.observation})
    # Information through close t; execution at close t+1; return t+1 -> t+2.
    d["target_observation"] = prices.observation.shift(-2)
    d["target"] = ret.FTSE.shift(-2)
    basic = []
    for lag in range(5):
        name = f"FTSE_lag{lag}"
        d[name] = ret.FTSE.shift(lag)
        basic.append(name)
    richer = basic.copy()
    for market in markets:
        for window in [5, 20]:
            mom = f"{market}_momentum{window}"
            vol = f"{market}_volatility{window}"
            d[mom] = prices[market].pct_change(window, fill_method=None)
            d[vol] = ret[market].rolling(window).std()
            richer += [mom, vol]
        if market != "FTSE":
            name = f"{market}_return"
            d[name] = ret[market]
            richer.append(name)
    d = d.dropna().reset_index(drop=True)
    assert np.isfinite(d.to_numpy()).all()
    return prices, d, basic, richer

def investment_metrics(returns):
    wealth = np.r_[1., np.cumprod(1 + returns)]
    vol = np.std(returns, ddof=1)
    return dict(total_return=wealth[-1]-1,
                annualized_return=wealth[-1]**(252/len(returns))-1,
                annualized_volatility=vol*np.sqrt(252),
                sharpe_zero_cash=np.mean(returns)/vol*np.sqrt(252) if vol > 0 else 0.,
                max_drawdown=np.min(wealth/np.maximum.accumulate(wealth)-1))

def main():
    class_results = reproduce_class_simulation()
    prices, d, basic, richer = make_data()
    n = len(d)
    a, b = int(n*.6), int(n*.8)
    train, valid, test = d.iloc[:a-2], d.iloc[a:b-2], d.iloc[b:]
    # Purge the last two feature rows at each boundary, including refitting.
    fit = d.iloc[:b-2]
    assert train.target_observation.max() < valid.feature_observation.min()
    assert fit.target_observation.max() < test.feature_observation.min()
    grid = ParameterGrid(dict(n_estimators=[50, 150], learning_rate=[.01, .03],
                             max_depth=[1, 2], min_samples_leaf=[20, 50]))
    tuning = []
    for params in grid:
        m = GradientBoostingRegressor(**params, random_state=SEED).fit(train[richer], train.target)
        tuning.append({**params, "validation_mse": mean_squared_error(valid.target, m.predict(valid[richer]))})
    tuning = pd.DataFrame(tuning).sort_values("validation_mse", kind="stable")
    tuning.to_csv(OUT / "validation_search.csv", index=False)
    best = tuning.iloc[0]
    params = {k: int(best[k]) for k in ["n_estimators", "max_depth", "min_samples_leaf"]}
    params["learning_rate"] = float(best.learning_rate)
    models = {"Class-settings baseline": GradientBoostingRegressor(**CLASS_PARAMS).fit(fit[basic], fit.target),
              "Tuned richer model": GradientBoostingRegressor(**params, random_state=SEED).fit(fit[richer], fit.target)}
    predictions = {"Historical mean": np.full(len(test), fit.target.mean()),
                   "Class-settings baseline": models["Class-settings baseline"].predict(test[basic]),
                   "Tuned richer model": models["Tuned richer model"].predict(test[richer])}
    y = test.target.to_numpy()
    denom = np.sum((y-fit.target.mean())**2)
    metrics, strategies, equity = [], [], {}
    prediction_output = test[["feature_observation", "target_observation", "target"]].copy()
    position_output = prediction_output.copy()
    cost = .001  # 10 basis points per unit one-way turnover, fixed before testing.
    for name, p in predictions.items():
        metrics.append(dict(model=name, rmse=np.sqrt(mean_squared_error(y, p)),
                            mae=mean_absolute_error(y, p),
                            directional_accuracy=np.mean((p > 0) == (y > 0)),
                            r2_vs_historical_mean=1-np.sum((y-p)**2)/denom))
        prediction_output[name] = p
    for name, p in {**predictions, "Buy and hold": np.ones(len(y))}.items():
        position = (p > 0).astype(float)
        turnover = np.abs(np.diff(np.r_[0., position]))
        # Charge liquidation on the final observation as well.
        turnover[-1] += position[-1]
        gross = position*y
        net = gross-cost*turnover
        strategies.append(dict(strategy=name, **investment_metrics(net),
                               gross_total_return=np.prod(1+gross)-1,
                               exposure=position.mean(), one_way_turnover=turnover.sum()))
        equity[name] = np.cumprod(1+net)
        position_output[name+"_position"] = position
        position_output[name+"_net_return"] = net
    metrics = pd.DataFrame(metrics)
    strategies = pd.DataFrame(strategies)
    metrics.to_csv(OUT / "predictive_metrics.csv", index=False)
    strategies.to_csv(OUT / "investment_metrics.csv", index=False)
    prediction_output.to_csv(OUT / "test_predictions.csv", index=False)
    position_output.to_csv(OUT / "test_positions_and_returns.csv", index=False)
    d.to_csv(OUT / "features.csv", index=False)
    split_rows = []
    for name, frame in [("Training", train), ("Validation", valid), ("Final refit", fit), ("Test", test)]:
        split_rows.append(dict(split=name, rows=len(frame),
                               feature_start=int(frame.feature_observation.min()),
                               feature_end=int(frame.feature_observation.max()),
                               target_end=int(frame.target_observation.max())))
    pd.DataFrame(split_rows).to_csv(OUT / "splits.csv", index=False)
    # Training vs validation loss by boosting stage; test data never select a stage.
    original = GradientBoostingRegressor(**CLASS_PARAMS).fit(train[basic], train.target)
    learning = pd.DataFrame({"trees": np.arange(1, 301),
                            "train_mse": [mean_squared_error(train.target, p) for p in original.staged_predict(train[basic])],
                            "validation_mse": [mean_squared_error(valid.target, p) for p in original.staged_predict(valid[basic])]})
    learning.to_csv(OUT / "learning_curve.csv", index=False)
    fig, ax = plt.subplots(figsize=(8, 3.7))
    for col, label in [("train_mse", "Training"), ("validation_mse", "Validation")]:
        ax.plot(learning.trees, learning[col]*1e4, label=label)
    ax.set(xlabel="Number of boosting trees", ylabel="MSE (percentage points squared)", title="Fitting the past can worsen future predictions")
    ax.legend(frameon=False)
    savefig("learning_curve.png")
    fig, ax = plt.subplots(figsize=(8, 3.7))
    ax.barh(metrics.model, metrics.rmse*100, color=["#8997a4", "#bb6a46", "#205c78"])
    ax.set(xlabel="Test RMSE (percentage points; lower is better)", title="Do complex forecasts beat the historical mean?")
    savefig("test_rmse.png")
    fig, ax = plt.subplots(figsize=(8, 4.2))
    colors = ["#8997a4", "#bb6a46", "#205c78", "#477b50"]
    for (name, wealth), color in zip(equity.items(), colors):
        ax.plot(np.arange(len(y)+1), np.r_[1., wealth], label=name, color=color)
    ax.axhline(1, color="gray", lw=.6)
    ax.set(xlabel="Held-out trading observations", ylabel="Wealth from an initial 1", title="Long-or-cash strategies after 10 bp one-way costs")
    ax.legend(frameon=False, fontsize=8)
    savefig("net_wealth.png")
    sensitivity = []
    p = (predictions["Tuned richer model"] > 0).astype(float)
    turn = np.abs(np.diff(np.r_[0., p])); turn[-1] += p[-1]
    for bp in [0, 5, 10, 25]:
        sensitivity.append(dict(cost_bp=bp, **investment_metrics(p*y-bp/10000*turn)))
    pd.DataFrame(sensitivity).to_csv(OUT / "cost_sensitivity.csv", index=False)
    summary = dict(selected_parameters=params, baseline_parameters=CLASS_PARAMS,
                   n_observations=n, test_observations=len(test),
                   simple_features=basic, richer_features=richer,
                   class_simulation=class_results,
                   versions=dict(python=platform.python_version(), sklearn=sklearn.__version__,
                                 numpy=np.__version__, pandas=pd.__version__, matplotlib=matplotlib.__version__),
                   data_period="1991-1998; observation order only; no daily calendar dates provided",
                   trading_rule="Signal through t; execution t+1 close; return t+1 to t+2; long iff forecast > 0",
                   cash_return=0, cost_basis_points=10)
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2)+"\n")
    print(metrics.to_string(index=False))
    print(strategies.to_string(index=False))
    print("Selected:", params)

if __name__ == "__main__":
    main()
