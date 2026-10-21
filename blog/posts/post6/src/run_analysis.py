"""Reproduce the synthetic parent-child income panel and SQL IGE analysis."""
from __future__ import annotations

import csv
import math
import random
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
OUT = ROOT / "outputs"
FIG = OUT / "figures"
SEED = 20261021
N_FAMILIES = 5_000
TRUE_IGE = 0.40


def generate_panel(n: int = N_FAMILIES, seed: int = SEED):
    """Create a reproducible two-generation panel with known long-run IGE."""
    rng = random.Random(seed)
    members, incomes = [], []
    for family_id in range(1, n + 1):
        parent_id, child_id = family_id * 2, family_id * 2 + 1
        parent_perm = rng.gauss(10.55, 0.42)
        child_perm = 9.92 + TRUE_IGE * (parent_perm - 10.55) + rng.gauss(0, 0.31)
        members.extend([
            {"person_id": parent_id, "family_id": family_id, "role": "parent"},
            {"person_id": child_id, "family_id": family_id, "role": "child"},
        ])
        # Parent observations cover ages 25–49; child observations cover ages 22–39. Earnings are
        # less stable early in the career; single-year log-income measurement
        # error falls with age, so early parent income attenuates the IGE.
        for age in range(25, 50):
            age_profile = 0.012 * (age - 40) - 0.0005 * (age - 40) ** 2
            shock_sd = 1.20 if age == 25 else (0.65 if age == 30 else (0.35 if age >= 35 else 0.50))
            log_income = parent_perm + age_profile + rng.gauss(0, shock_sd)
            incomes.append({"person_id": parent_id, "year": 1980 + age - 25, "age": age,
                            "annual_income": math.exp(log_income)})
        for age in range(22, 40):
            age_profile = 0.045 * (age - 30) - 0.0012 * (age - 30) ** 2
            shock_sd = 1.20 if age == 25 else (0.65 if age == 30 else (0.25 if age >= 35 else 0.50))
            log_income = child_perm + age_profile + rng.gauss(0, shock_sd)
            incomes.append({"person_id": child_id, "year": 2000 + age - 22, "age": age,
                            "annual_income": math.exp(log_income)})
    return members, incomes


def write_csv(path: Path, rows: list[dict], fields: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def ols(x: list[float], y: list[float]) -> tuple[float, float, float]:
    n = len(x)
    xbar, ybar = sum(x) / n, sum(y) / n
    sxx = sum((v - xbar) ** 2 for v in x)
    slope = sum((a - xbar) * (b - ybar) for a, b in zip(x, y)) / sxx
    intercept = ybar - slope * xbar
    residual_ss = sum((b - intercept - slope * a) ** 2 for a, b in zip(x, y))
    se = math.sqrt((residual_ss / (n - 2)) / sxx)
    return slope, se, intercept


def write_bar_chart(path: Path, estimates: list[dict]) -> None:
    width, height = 900, 520
    left, top, plot_w, plot_h = 100, 85, 730, 330
    ymax = max(0.60, max(float(e["ige"]) for e in estimates) + 0.10)
    labels = ["Both age 25\n(single year)", "Both age 30\n(single year)",
              "Both age 35\n(single year)", "Ages 35–39\n(five-year mean)"]
    colors = ["#c44e52", "#dd8452", "#4c72b0", "#55a868"]
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
           '<rect width="100%" height="100%" fill="white"/>',
           '<style>text{font-family:Arial,sans-serif;fill:#222}.small{font-size:13px}.axis{stroke:#555;stroke-width:1}.grid{stroke:#ddd;stroke-width:1}</style>',
           '<text x="450" y="35" font-size="21" text-anchor="middle">Early-career income understates persistence</text>']
    for tick_i in range(0, 7):
        val = tick_i / 10
        y = top + plot_h - val / ymax * plot_h
        svg.append(f'<line class="grid" x1="{left}" y1="{y:.1f}" x2="{left+plot_w}" y2="{y:.1f}"/>')
        svg.append(f'<text class="small" x="{left-12}" y="{y+4:.1f}" text-anchor="end">{val:.1f}</text>')
    true_y = top + plot_h - TRUE_IGE / ymax * plot_h
    svg.append(f'<line x1="{left}" y1="{true_y:.1f}" x2="{left+plot_w}" y2="{true_y:.1f}" stroke="#222" stroke-dasharray="7,5" stroke-width="2"/>')
    svg.append(f'<text class="small" x="{left+plot_w-4}" y="{true_y-8:.1f}" text-anchor="end">True simulated IGE = {TRUE_IGE:.2f}</text>')
    bar_w, gap = 115, 62
    start = left + 40
    for i, e in enumerate(estimates):
        x = start + i * (bar_w + gap)
        val = float(e["ige"])
        bh = val / ymax * plot_h
        y = top + plot_h - bh
        svg.append(f'<rect x="{x}" y="{y:.1f}" width="{bar_w}" height="{bh:.1f}" fill="{colors[i]}"/>')
        svg.append(f'<text x="{x+bar_w/2}" y="{y-9:.1f}" text-anchor="middle" font-size="14">{val:.2f}</text>')
        for j, line in enumerate(labels[i].split("\n")):
            svg.append(f'<text class="small" x="{x+bar_w/2}" y="{top+plot_h+22+j*17}" text-anchor="middle">{line}</text>')
    svg += [f'<line class="axis" x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}"/>',
            f'<line class="axis" x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}"/>',
            f'<text x="25" y="{top+plot_h/2}" transform="rotate(-90 25 {top+plot_h/2})" text-anchor="middle" font-size="15">Estimated intergenerational elasticity</text>', '</svg>']
    path.write_text("\n".join(svg), encoding="utf-8")


def write_scatter(path: Path, matched: list[dict], slope: float, intercept: float) -> None:
    width, height = 760, 560
    left, top, pw, ph = 90, 70, 610, 400
    xs = [math.log(float(r["parent_avg_35_39_income"])) for r in matched]
    ys = [math.log(float(r["child_avg_35_39_income"])) for r in matched]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    def px(v): return left + (v - xmin) / (xmax - xmin) * pw
    def py(v): return top + ph - (v - ymin) / (ymax - ymin) * ph
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
           '<rect width="100%" height="100%" fill="white"/>',
           '<style>text{font-family:Arial,sans-serif;fill:#222}.grid{stroke:#ddd}.axis{stroke:#555}</style>',
           '<text x="380" y="32" font-size="20" text-anchor="middle">Long-run parent and child income</text>']
    for i in range(5):
        xv = xmin + i * (xmax - xmin) / 4
        yv = ymin + i * (ymax - ymin) / 4
        x, y = px(xv), py(yv)
        svg.append(f'<line class="grid" x1="{x:.1f}" y1="{top}" x2="{x:.1f}" y2="{top+ph}"/>')
        svg.append(f'<text x="{x:.1f}" y="{top+ph+22}" font-size="12" text-anchor="middle">{xv:.1f}</text>')
        svg.append(f'<line class="grid" x1="{left}" y1="{y:.1f}" x2="{left+pw}" y2="{y:.1f}"/>')
        svg.append(f'<text x="{left-10}" y="{y+4:.1f}" font-size="12" text-anchor="end">{yv:.1f}</text>')
    # Show every 10th family to keep the SVG compact while retaining the full CSV.
    for r in matched[::10]:
        x = math.log(float(r["parent_avg_35_39_income"]))
        y = math.log(float(r["child_avg_35_39_income"]))
        svg.append(f'<circle cx="{px(x):.1f}" cy="{py(y):.1f}" r="2.1" fill="#4c72b0" fill-opacity="0.38"/>')
    xa, xb = xmin, xmax
    ya, yb = intercept + slope * xa, intercept + slope * xb
    svg.append(f'<line x1="{px(xa):.1f}" y1="{py(ya):.1f}" x2="{px(xb):.1f}" y2="{py(yb):.1f}" stroke="#c44e52" stroke-width="3"/>')
    svg += [f'<line class="axis" x1="{left}" y1="{top+ph}" x2="{left+pw}" y2="{top+ph}"/>',
            f'<line class="axis" x1="{left}" y1="{top}" x2="{left}" y2="{top+ph}"/>',
            f'<text x="{left+pw/2}" y="{height-20}" font-size="14" text-anchor="middle">Parent mean log income, ages 35–39</text>',
            f'<text x="24" y="{top+ph/2}" transform="rotate(-90 24 {top+ph/2})" font-size="14" text-anchor="middle">Child mean log income, ages 35–39</text>', '</svg>']
    path.write_text("\n".join(svg), encoding="utf-8")


def main() -> None:
    DATA.mkdir(exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    members, incomes = generate_panel()
    write_csv(DATA / "family_members.csv", members, ["person_id", "family_id", "role"])
    write_csv(DATA / "income_panel.csv", incomes, ["person_id", "year", "age", "annual_income"])

    db_path = OUT / "parent_child_panel.sqlite"
    if db_path.exists():
        db_path.unlink()
    with sqlite3.connect(db_path) as con:
        con.row_factory = sqlite3.Row
        con.create_function("LOG", 1, math.log)
        con.create_function("EXP", 1, math.exp)
        con.execute("CREATE TABLE family_members (person_id INTEGER, family_id INTEGER, role TEXT)")
        con.execute("CREATE TABLE income (person_id INTEGER, year INTEGER, age INTEGER, annual_income REAL)")
        con.executemany("INSERT INTO family_members VALUES (:person_id, :family_id, :role)", members)
        con.executemany("INSERT INTO income VALUES (:person_id, :year, :age, :annual_income)", incomes)
        query = (ROOT / "sql" / "parent_child_ige.sql").read_text(encoding="utf-8")
        matched = [dict(row) for row in con.execute(query).fetchall()]

    columns = ["family_id", "parent_person_id", "child_person_id", "parent_age25_income", "parent_age30_income", "parent_age35_income",
               "parent_avg_35_39_income", "child_age25_income", "child_age30_income",
               "child_age35_income", "child_avg_35_39_income"]
    measures = ["parent_age25_income", "parent_age30_income", "parent_age35_income",
                "parent_avg_35_39_income", "child_age25_income",
                "child_age30_income", "child_age35_income", "child_avg_35_39_income"]
    for row in matched:
        for col in measures:
            if row[col] is None or row[col] <= 0:
                raise ValueError(f"Missing or nonpositive income in {col}; define and document a sample rule.")

    specs = [
        ("Single year: both generations at age 25", "parent_age25_income", "child_age25_income"),
        ("Single year: both generations at age 30", "parent_age30_income", "child_age30_income"),
        ("Single year: both generations at age 35", "parent_age35_income", "child_age35_income"),
        ("Five-year mean: both generations ages 35–39", "parent_avg_35_39_income", "child_avg_35_39_income"),
    ]
    estimates = []
    for label, xcol, ycol in specs:
        x = [math.log(r[xcol]) for r in matched]
        y = [math.log(r[ycol]) for r in matched]
        slope, se, intercept = ols(x, y)
        estimates.append({"measure": label, "n_families": len(matched), "ige": slope,
                          "std_error": se, "ci95_low": slope - 1.96 * se,
                          "ci95_high": slope + 1.96 * se, "true_ige": TRUE_IGE})
    write_csv(OUT / "matched_parent_child.csv", matched, columns)
    write_csv(OUT / "matched_sample_preview.csv", matched[:12], columns)
    write_csv(OUT / "ige_estimates.csv", estimates,
              ["measure", "n_families", "ige", "std_error", "ci95_low", "ci95_high", "true_ige"])
    write_bar_chart(FIG / "ige_lifecycle_comparison.svg", estimates)
    long_x = [math.log(r["parent_avg_35_39_income"]) for r in matched]
    long_y = [math.log(r["child_avg_35_39_income"]) for r in matched]
    long_slope, _, long_intercept = ols(long_x, long_y)
    write_scatter(FIG / "ige_long_run_scatter.svg", matched, long_slope, long_intercept)

    print("measure | n | IGE | SE | 95% CI")
    for e in estimates:
        print(f"{e['measure']} | {e['n_families']} | {e['ige']:.3f} | {e['std_error']:.3f} | [{e['ci95_low']:.3f}, {e['ci95_high']:.3f}]")
    print(f"\nWrote reproducible outputs beneath {ROOT}")


if __name__ == "__main__":
    main()
