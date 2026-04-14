# ASBench

ASBench is a modular Nextflow DSL2 pipeline for benchmarking representative short-read RNA-seq workflows for transcript quantification, differential analysis, alternative splicing analysis, and quality assessment.

The current repository includes workflow modules, QC resources, reference-based evaluation materials, and documentation for both benchmarking and practical execution.

## Overview

ASBench provides a unified framework for running and comparing combinations of:

- alignment
- isoform quantification
- gene-level quantification
- differential expression analysis
- alternative splicing event analysis
- basic QC assessment
- reference-based quality scoring

The workflow is organized as reusable Nextflow DSL2 modules plus companion Python and R utilities.

## Current project structure

```text
ASBench/
├── assets/
│   ├── fastq_screen.conf
│   └── samplesheet.template.csv
├── basic_qc/
│   ├── basic_qc_metrics.tsv
│   ├── qc_baseline.tsv
│   └── qc_cutoffs.tsv
├── basic_qc_parameters_and_cutoffs.md
├── bin/
│   ├── build_counts_matrix.py
│   ├── build_tpm_matrix.py
│   ├── deseq2.R
│   ├── edger_ql.R
│   ├── junction_accuracy.py
│   ├── limma_voom.R
│   ├── prepDE.py
│   └── run_junction_accuracy_nf.py
├── conf/
│   ├── modules.config
│   └── wehi_slurm.config
├── demo/
│   └── downsample_1M/
├── figures/
│   ├── qc_distribution_post_alignment.pdf
│   ├── qc_distribution_post_alignment.png
│   ├── qc_distribution_pre_alignment.pdf
│   ├── qc_distribution_pre_alignment.png
│   ├── qc_distribution_snr.pdf
│   └── qc_distribution_snr.png
├── ground_truth/
├── main.nf
├── modules/
│   ├── align/
│   ├── as_event/
│   ├── de/
│   ├── qc/
│   ├── qc_metrics/
│   ├── quantify_gene/
│   ├── quantify_isoform/
│   └── utils/
├── nextflow.config
├── optimal_workflow_execution.md
├── output/
├── README.md
├── reference_based_quality_scores.md
├── reference_quality/
│   ├── data/
│   ├── figures/
│   ├── output/
│   ├── reference_based_quality_scores.md
│   └── scripts/
├── scripts/
│   ├── build_gene_count_matrix.py
│   ├── build_majiq_config.py
│   ├── build_quant_matrix.py
│   ├── plot_qc_distribution.py
│   ├── run_deseq2.R
│   ├── run_limma.R
│   └── run_suppa2_diffsplice.py
└── test.sh
```

## Supported workflow components

### Alignment
- `STAR`
- `HISAT2`

### Isoform quantification
- `StringTie / Ballgown`
- `RSEM`
- `eXpress`
- `Cuffdiff`
- `prepDE`

### Differential analysis
- `DESeq2`
- `edgeR QL`
- `limma`
- `limma-voom`

### Alternative splicing / event analysis
- `SUPPA2`
- `MAJIQ`
- `rMATS` is documented as a recommended optimal event workflow, although it is not currently present as a module in this repository.

### Basic QC
- `FastQC`
- `FastQ Screen`
- `Qualimap`
- `MultiQC`

### QC metrics / reference evaluation
- junction accuracy evaluation
- QC baseline comparison
- reference-based quality score calculation for junctions, isoforms, and events

## Nextflow modules currently included

### `modules/align`
- `star.nf`
- `hisat2.nf`
- `hisat2_cuffdiff.nf`

### `modules/quantify_isoform`
- `stringtie_ballgown.nf`
- `rsem.nf`
- `express.nf`
- `cuffdiff.nf`
- `prepde.nf`

### `modules/quantify_gene`
- `cuffdiff.nf`

### `modules/de`
- `deseq2.nf`
- `edger_ql.nf`
- `limma.nf`
- `limma_voom.nf`

### `modules/as_event`
- `suppa2_events.nf`
- `suppa2_psi.nf`
- `suppa2_merge_group.nf`
- `suppa2_diffsplice.nf`
- `majiq_build.nf`
- `majiq_delta_psi.nf`

### `modules/qc`
- `fastqc.nf`
- `fastq_screen.nf`
- `multiqc.nf`
- `qualimap.nf`

### `modules/qc_metrics`
- `junction_accuracy_all.nf`

### `modules/utils`
- `build_gene_count_matrix.nf`
- `build_quant_matrix.nf`
- `build_majiq_config.nf`

## Requirements

- Nextflow DSL2
- Java 11 or above
- Python 3 with common scientific packages as needed
- R with required analysis packages as needed
- Apptainer / Singularity recommended for reproducibility

Typical tool dependencies used across modules:

- STAR
- HISAT2
- StringTie
- SUPPA2
- MAJIQ
- RSEM
- eXpress
- Cuffdiff
- FastQC
- FastQ Screen
- Qualimap
- MultiQC
- DESeq2
- edgeR
- limma

## Input samplesheet

Example:

```csv
sample,group,strandedness,fastq1,fastq2
D5_1,control,unstranded,/path/D5_1_R1.fq.gz,/path/D5_1_R2.fq.gz
D5_2,control,unstranded,/path/D5_2_R1.fq.gz,/path/D5_2_R2.fq.gz
D6_1,test,unstranded,/path/D6_1_R1.fq.gz,/path/D6_1_R2.fq.gz
D6_2,test,unstranded,/path/D6_2_R1.fq.gz,/path/D6_2_R2.fq.gz
```

Columns:

- `sample`: unique sample identifier
- `group`: biological group or comparison group
- `strandedness`: library strandedness
- `fastq1`, `fastq2`: paired-end FASTQ paths

## Usage

### General syntax

```bash
nextflow run main.nf \
  -profile wehi \
  --pipeline <pipeline_name> \
  --samplesheet assets/samplesheet.template.csv \
  --outdir results \
  [additional parameters]
```

## Representative workflow combinations

### 1. STAR + StringTie + SUPPA2

```text
FASTQ
→ STAR
→ StringTie / Ballgown
→ SUPPA2 event generation
→ sample-level PSI / TPM
→ group-level merge
→ SUPPA2 diffSplice
```

### 2. HISAT2 + Cuffdiff

```text
FASTQ
→ HISAT2
→ Cuffdiff
```

### 3. STAR + eXpress + limma

```text
FASTQ
→ STAR
→ eXpress
→ quant matrix construction
→ limma
```

### 4. STAR + RSEM + DESeq2

```text
FASTQ
→ STAR
→ RSEM
→ quant matrix construction
→ DESeq2
```

### 5. STAR + MAJIQ

```text
FASTQ
→ STAR
→ MAJIQ config generation
→ MAJIQ build
→ MAJIQ deltapsi
```

## Basic QC resources

The repository now includes a dedicated basic QC section:

- `basic_qc/basic_qc_metrics.tsv`
- `basic_qc/qc_baseline.tsv`
- `basic_qc/qc_cutoffs.tsv`
- `basic_qc_parameters_and_cutoffs.md`

This part documents:

- pre-alignment QC
- post-alignment QC
- SNR-based QC
- QC cutoff interpretation
- QC distribution plotting

QC distribution figures are currently stored in the top-level `figures/` directory:

- `figures/qc_distribution_pre_alignment.png`
- `figures/qc_distribution_post_alignment.png`
- `figures/qc_distribution_snr.png`

The plotting utility is:

- `scripts/plot_qc_distribution.py`

## Reference-based quality score resources

The repository also includes a dedicated reference-based evaluation section:

- `reference_based_quality_scores.md`
- `reference_quality/reference_based_quality_scores.md`

The `reference_quality/` directory contains:

### Data
- `42_lab_consistency_distribution_clean.csv`
- `42_lab_consistency_distribution.csv`
- `Junction_anotated_truth.csv`
- `Junction_novel_truth.csv`
- `Ratio-based_AS_reference_datasets.csv`
- `Ratio-based_DAS_reference_datasets.csv.csv`
- `RefData_DEIs_all_isoforms_classified_u_20250522.csv`
- `ref_expr_b7_p4_s84_u_20250516.csv`

### Scripts
- `compute_junction_quality_scores.py`
- `compute_isoform_rmse_scores.py`
- `compute_event_pcc_scores.py`
- `compute_reference_quality.py`
- `plot_reference_quality_distributions.py`

### Current outputs
- `reference_quality/output/junction_quality_scores.tsv`
- `reference_quality/output/isoform_quality_scores.tsv`
- `reference_quality/output/event_quality_scores.tsv`

### Current figures
- `reference_quality/figures/junction_f1_distribution.png`
- `reference_quality/figures/junction_novel_fnr_distribution.png`
- `reference_quality/figures/isoform_rmse_distribution.png`
- `reference_quality/figures/event_pcc_distribution.png`

## Optimal workflow recommendation

A dedicated summary document is included:

- `optimal_workflow_execution.md`

Current recommended best-practice summary:

### Isoform
```text
STAR + (RSEM / eXpress / Cuffdiff) + edgeR v1/v2
```

### Event
```text
STAR + SUPPA2 / rMATS
```

## Utility scripts

### Top-level `scripts/`
- `build_gene_count_matrix.py`
- `build_majiq_config.py`
- `build_quant_matrix.py`
- `plot_qc_distribution.py`
- `run_deseq2.R`
- `run_limma.R`
- `run_suppa2_diffsplice.py`

### `bin/`
- `build_counts_matrix.py`
- `build_tpm_matrix.py`
- `deseq2.R`
- `edger_ql.R`
- `junction_accuracy.py`
- `limma_voom.R`
- `prepDE.py`
- `run_junction_accuracy_nf.py`

## Configuration

Configuration files currently included:

- `nextflow.config`
- `conf/modules.config`
- `conf/wehi_slurm.config`

## Demo data

The repository includes a small demo dataset:

- `demo/downsample_1M/`

This contains downsampled paired-end FASTQ files for D5 and D6 samples for lightweight testing.

## Typical outputs

Depending on the selected branch, results are typically organized into:

```text
results/
├── 02_align/
├── 03_quant/
├── 04_matrix/
├── 05_de/
└── 05_as/
```

Additional QC and evaluation outputs may be written into:

- `basic_qc/`
- `figures/`
- `output/`
- `reference_quality/output/`
- `reference_quality/figures/`

## Notes and current limitations

- The repository includes representative benchmark workflows rather than every possible tool combination.
- `rMATS` is currently described in the optimal workflow recommendation but is not yet implemented as a module in `modules/`.
- Some scripts still use placeholder or manually supplied input values and may require project-specific adaptation before production use.
- The repository contains both top-level and `reference_quality/`-specific documentation; keep them synchronized when updating workflows.
- `ground_truth/` is present in the repository but its internal structure is not documented here yet.

## Documentation included

Current documentation files include:

- `README.md`
- `basic_qc_parameters_and_cutoffs.md`
- `reference_based_quality_scores.md`
- `reference_quality/reference_based_quality_scores.md`
- `optimal_workflow_execution.md`

## Contact

**Maintainer**

Qingwang Chen  
`qwchen20@fudan.edu.cn`

Duo Wang  
`18801232285@163.com`

Project: **ASBench (Alternative Splicing Benchmarking)**
