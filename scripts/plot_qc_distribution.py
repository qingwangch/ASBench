#!/usr/bin/env python3
import argparse
import math
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PRE_ALIGNMENT = [
    "Strand specificity",
    "Number of Reads (million)",
    "Number of paired-end reads (million)",
    "Q30 (%)",
    "Q20 (%)",
    "GC (%)",
    "Paired-end reads length (bp)",
    "Duplicate rate (%)",
]

POST_ALIGNMENT = [
    "Unique mapped (%)",
    "Unmapped (%)",
    "Multiple mapped (%)",
    "Total mapped (%)",
    "Mismatch bases rate (%)",
    "5' - 3' bias",
    "Mapped to exonic region (%)",
    "Mapped to intronic region (%)",
    "Mapped to intergentic region (%)",
]

SNR_METRICS = [
    "Gene-level SNR",
    "Isoform-level SNR",
    "AS event-level SNR",
]


def load_table(path: str) -> pd.DataFrame:
    return pd.read_csv(path, sep=None, engine="python")


def load_baseline(path: str) -> pd.DataFrame:
    df = load_table(path)
    if df.columns[0].lower() != "lab":
        df = df.rename(columns={df.columns[0]: "lab"})
    df = df[df["lab"].astype(str) != "QC cutoff"].copy()
    for c in df.columns[1:]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    return df


def load_input_metrics(path: str) -> pd.DataFrame:
    df = load_table(path)
    first = df.columns[0]
    if first.lower() != "sample":
        df = df.rename(columns={first: "Sample"})
    elif first != "Sample":
        df = df.rename(columns={first: "Sample"})
    for c in df.columns[1:]:
        df[c] = pd.to_numeric(df[c], errors="ignore")
    return df


def load_cutoffs(path: str) -> pd.DataFrame:
    df = load_table(path)
    cols = {c.lower(): c for c in df.columns}
    if "metric" not in cols:
        raise ValueError("Cutoff table must contain a 'metric' column")
    if "cutoff" not in cols:
        raise ValueError("Cutoff table must contain a 'cutoff' column")
    metric_col = cols["metric"]
    cutoff_col = cols["cutoff"]
    out = df[[metric_col, cutoff_col]].copy()
    out.columns = ["metric", "cutoff"]
    return out


def parse_cutoff(cutoff):
    if pd.isna(cutoff):
        return {"rule": "none"}
    s = str(cutoff).strip()
    if s in {"", "/"}:
        return {"rule": "none"}
    if s.startswith(">"):
        return {"rule": "gt", "value": float(s[1:])}
    if s.startswith("<"):
        return {"rule": "lt", "value": float(s[1:])}
    if "-" in s:
        left, right = s.split("-", 1)
        return {"rule": "range", "low": float(left), "high": float(right)}
    return {"rule": "none"}


def evaluate_pass_fail(value, cutoff):
    parsed = parse_cutoff(cutoff)
    if pd.isna(value) or parsed["rule"] == "none":
        return "NA"
    try:
        v = float(value)
    except Exception:
        return "NA"
    if parsed["rule"] == "gt":
        return "PASS" if v > parsed["value"] else "FAIL"
    if parsed["rule"] == "lt":
        return "PASS" if v < parsed["value"] else "FAIL"
    if parsed["rule"] == "range":
        return "PASS" if parsed["low"] <= v <= parsed["high"] else "FAIL"
    return "NA"


def draw_cutoff_lines(ax, cutoff):
    parsed = parse_cutoff(cutoff)
    if parsed["rule"] == "gt":
        ax.axhline(parsed["value"], linestyle="--", linewidth=1)
    elif parsed["rule"] == "lt":
        ax.axhline(parsed["value"], linestyle="--", linewidth=1)
    elif parsed["rule"] == "range":
        ax.axhline(parsed["low"], linestyle="--", linewidth=1)
        ax.axhline(parsed["high"], linestyle="--", linewidth=1)


def plot_group(baseline, observed, metrics, cutoffs, title, out_png, out_pdf):
    metrics = [m for m in metrics if m in baseline.columns and m in observed.columns]
    if not metrics:
        return

    n = len(metrics)
    ncols = 2
    nrows = math.ceil(n / ncols)

    fig, axes = plt.subplots(nrows, ncols, figsize=(12, 4 * nrows))
    axes = axes.flatten() if hasattr(axes, "flatten") else [axes]

    cutoff_map = dict(zip(cutoffs["metric"], cutoffs["cutoff"]))

    for ax, metric in zip(axes, metrics):
        bg = baseline[metric].dropna().tolist()
        if bg:
            ax.scatter([0] * len(bg), bg, alpha=0.45, s=20, label="42 labs")

        vals = observed[["Sample", metric]].dropna()
        cutoff = cutoff_map.get(metric, "/")
        draw_cutoff_lines(ax, cutoff)

        for _, row in vals.iterrows():
            status = evaluate_pass_fail(row[metric], cutoff)
            color = {"PASS": "tab:green", "FAIL": "tab:red", "NA": "tab:blue"}.get(status, "tab:blue")
            ax.scatter([1], [row[metric]], s=55, color=color)
            ax.text(1.03, row[metric], f'{row["Sample"]} ({status})', fontsize=8, va="center")

        ax.set_title(f"{metric}\ncutoff: {cutoff}")
        ax.set_xticks([0, 1])
        ax.set_xticklabels(["42 labs", "input"])
        ax.set_xlim(-0.4, 1.65)

    for ax in axes[n:]:
        ax.axis("off")

    fig.suptitle(title, fontsize=14)
    fig.tight_layout()
    fig.savefig(out_png, dpi=300, bbox_inches="tight")
    fig.savefig(out_pdf, bbox_inches="tight")
    plt.close(fig)


def main():
    ap = argparse.ArgumentParser(
        description="Plot QC metric distributions relative to the 42-lab reference set with cutoff lines and pass/fail highlighting."
    )
    ap.add_argument("--baseline", required=True, help="42-lab QC baseline table")
    ap.add_argument("--input-metrics", required=True, help="Input sample QC metrics table")
    ap.add_argument("--cutoffs", required=True, help="QC cutoff table with columns: metric, cutoff")
    ap.add_argument("--outdir", required=True, help="Output directory")
    args = ap.parse_args()

    baseline = load_baseline(args.baseline)
    observed = load_input_metrics(args.input_metrics)
    cutoffs = load_cutoffs(args.cutoffs)

    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    plot_group(
        baseline,
        observed,
        PRE_ALIGNMENT,
        cutoffs,
        "Pre-alignment QC distribution",
        outdir / "qc_distribution_pre_alignment.png",
        outdir / "qc_distribution_pre_alignment.pdf",
    )
    plot_group(
        baseline,
        observed,
        POST_ALIGNMENT,
        cutoffs,
        "Post-alignment QC distribution",
        outdir / "qc_distribution_post_alignment.png",
        outdir / "qc_distribution_post_alignment.pdf",
    )
    plot_group(
        baseline,
        observed,
        SNR_METRICS,
        cutoffs,
        "SNR distribution",
        outdir / "qc_distribution_snr.png",
        outdir / "qc_distribution_snr.pdf",
    )


if __name__ == "__main__":
    main()