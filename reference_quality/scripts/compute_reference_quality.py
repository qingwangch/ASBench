#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import pandas as pd
import numpy as np

# ---------------------------
# Directories
# ---------------------------
data_dir = "../data"         # 数据目录
output_dir = "../output"     # 输出 TSV
figures_dir = "../figures"   # 输出图（可选）

os.makedirs(output_dir, exist_ok=True)
os.makedirs(figures_dir, exist_ok=True)

# ---------------------------
# Input files
# ---------------------------
lab42_file = os.path.join(data_dir, "42_lab_consistency_distribution_clean.csv")

# ---------------------------
# Helper functions
# ---------------------------
def compute_quality_score(input_val, lab_values, higher_is_better=True):
    """Compute quality score based on rank among 42 labs."""
    lab_values = [float(v) for v in lab_values if pd.notnull(v)]
    combined = lab_values + [float(input_val)]
    combined_sorted = sorted(combined, reverse=higher_is_better)
    rank = combined_sorted.index(float(input_val)) + 1
    score = (42 - rank) / 42
    return score

# ---------------------------
# Load lab42 consistency
# ---------------------------
lab42_df = pd.read_csv(lab42_file)
print("Columns in lab42_df:", lab42_df.columns.tolist())

# ---------------------------
# Input metrics (replace with STAR-StringTie-SUPPA2 calculation)
# ---------------------------
# Junction metrics
input_junction_f1_val = 0.95
input_junction_novel_fnr_val = 0.35

# Isoform RMSE
input_isoform_rmse_val = 0.36

# Event PCC
input_event_pcc_val = 0.92

# ---------------------------
# Column mapping
# ---------------------------
junction_f1_col = "junction_annotated_F1"
novel_fnr_col = "junction_novel_FNR"
isoform_rmse_col = "isoform_RMSE_quartet"
event_pcc_col = "event_PCC_quartet"

# ---------------------------
# Compute quality scores
# ---------------------------
score_junction_f1 = compute_quality_score(
    input_junction_f1_val,
    lab42_df[junction_f1_col].values,
    higher_is_better=True
)
score_junction_novel_fnr = compute_quality_score(
    input_junction_novel_fnr_val,
    lab42_df[novel_fnr_col].values,
    higher_is_better=False
)
score_isoform_rmse = compute_quality_score(
    input_isoform_rmse_val,
    lab42_df[isoform_rmse_col].values,
    higher_is_better=False  # RMSE smaller is better
)
score_event_pcc = compute_quality_score(
    input_event_pcc_val,
    lab42_df[event_pcc_col].values,
    higher_is_better=True
)

# ---------------------------
# Output TSVs
# ---------------------------
# Junction
junction_output = pd.DataFrame({
    "metric": ["junction_F1", "junction_novel_FNR"],
    "input_value": [input_junction_f1_val, input_junction_novel_fnr_val],
    "quality_score": [score_junction_f1, score_junction_novel_fnr],
    "pass_threshold": [0.5, 0.5],
    "pass": [score_junction_f1>0.5, score_junction_novel_fnr>0.5]
})
junction_output.to_csv(os.path.join(output_dir, "junction_quality_scores.tsv"),
                       sep="\t", index=False)

# Isoform
isoform_output = pd.DataFrame({
    "metric": ["isoform_RMSE"],
    "input_value": [input_isoform_rmse_val],
    "quality_score": [score_isoform_rmse],
    "pass_threshold": [0.5],
    "pass": [score_isoform_rmse>0.5]
})
isoform_output.to_csv(os.path.join(output_dir, "isoform_quality_scores.tsv"),
                      sep="\t", index=False)

# Event
event_output = pd.DataFrame({
    "metric": ["event_PCC"],
    "input_value": [input_event_pcc_val],
    "quality_score": [score_event_pcc],
    "pass_threshold": [0.5],
    "pass": [score_event_pcc>0.5]
})
event_output.to_csv(os.path.join(output_dir, "event_quality_scores.tsv"),
                    sep="\t", index=False)

print("Reference-based quality scores saved for junctions, isoform, and events.")