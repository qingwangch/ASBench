#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# ---------------------------
# Directories
# ---------------------------
output_dir = "../output"
figures_dir = "../figures"
os.makedirs(figures_dir, exist_ok=True)

# ---------------------------
# Input files
# ---------------------------
junction_file = os.path.join(output_dir, "junction_quality_scores.tsv")
isoform_file = os.path.join(output_dir, "isoform_quality_scores.tsv")
event_file = os.path.join(output_dir, "event_quality_scores.tsv")
lab42_file = "../data/42_lab_consistency_distribution_clean.csv"

# ---------------------------
# Load lab42 reference
# ---------------------------
lab42_df = pd.read_csv(lab42_file)

# ---------------------------
# Load junction scores
# ---------------------------
junction_df = pd.read_csv(junction_file, sep="\t")

# ---------------------------
# 1. Junction plots
# ---------------------------
plt.figure(figsize=(6,4))
sns.scatterplot(
    x=lab42_df['junction_annotated_F1'],
    y=[0]*len(lab42_df),
    label='42 labs', alpha=0.5
)
plt.scatter(junction_df['input_value'].iloc[0], 0, color='red', s=100, label='input sample')
plt.title('Annotated junction F1 distribution')
plt.xlabel('F1 score')
plt.yticks([])
plt.legend()
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "junction_f1_distribution.png"))
plt.close()

plt.figure(figsize=(6,4))
sns.scatterplot(
    x=lab42_df['junction_novel_FNR'],
    y=[0]*len(lab42_df),
    label='42 labs', alpha=0.5
)
plt.scatter(junction_df['input_value'].iloc[1], 0, color='red', s=100, label='input sample')
plt.title('Novel junction false negative rate distribution')
plt.xlabel('FNR')
plt.yticks([])
plt.legend()
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "junction_novel_fnr_distribution.png"))
plt.close()

# ---------------------------
# 2. Isoform RMSE
# ---------------------------
isoform_df = pd.read_csv(isoform_file, sep="\t")
plt.figure(figsize=(6,4))
sns.scatterplot(
    x=lab42_df['isoform_RMSE_quartet'],
    y=[0]*len(lab42_df),
    label='42 labs', alpha=0.5
)
plt.scatter(isoform_df['input_value'].iloc[0], 0, color='red', s=100, label='input sample')
plt.title('Isoform RMSE distribution')
plt.xlabel('RMSE')
plt.yticks([])
plt.legend()
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "isoform_rmse_distribution.png"))
plt.close()

# ---------------------------
# 3. Event PCC
# ---------------------------
event_df = pd.read_csv(event_file, sep="\t")
plt.figure(figsize=(6,4))
sns.scatterplot(
    x=lab42_df['event_PCC_quartet'],
    y=[0]*len(lab42_df),
    label='42 labs', alpha=0.5
)
plt.scatter(event_df['input_value'].iloc[0], 0, color='red', s=100, label='input sample')
plt.title('Event PCC distribution')
plt.xlabel('PCC')
plt.yticks([])
plt.legend()
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "event_pcc_distribution.png"))
plt.close()

print("All reference quality distribution plots saved in figures/ directory.")