# ASBench

ASBench is a modular Nextflow (DSL2) pipeline for benchmarking alternative splicing (AS) and isoform-level analyses using short-read RNA-seq data. It integrates alignment, quantification, differential expression, AS event detection, and splicing-aware QC in a unified, extensible framework.

## Contents

- [ASBench](#asbench)
  - [Contents](#contents)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Quick start](#quick-start)
    - [Prepare a samplesheet](#prepare-a-samplesheet)
    - [Run the pipeline](#run-the-pipeline)
  - [Pipeline overview](#pipeline-overview)
  - [Directory structure](#directory-structure)
    - [Key modules](#key-modules)
  - [Results structure](#results-structure)
    - [Standalone scripts](#standalone-scripts)
    - [Profiles and HPC](#profiles-and-hpc)
  - [Citation](#citation)
  - [Contact](#contact)

## Features

- Alignment with STAR or HISAT2
- Isoform and gene quantification via StringTie/Ballgown
- Alternative splicing analysis using SUPPA2 and MAJIQ
- Differential expression using DESeq2, edgeR, and limma-voom
- Junction- and splicing-aware QC metrics
- Fully modular Nextflow DSL2 design
- Slurm/HPC-ready configuration

## Requirements

- Nextflow 22.x or later (DSL2 enabled)
- Java 11 or later
- One of:
  - Singularity/Apptainer (recommended)
  - Conda (for local testing)
- Reference resources:
  - STAR index
  - GTF annotation (e.g. GENCODE)

## Quick start

### Prepare a samplesheet

Copy the template:

```bash
cp assets/samplesheet.template.csv my_samplesheet.csv
```
Samplesheet format:
```csv
sample,group,strandedness,fastq1,fastq2
D5_1,control,unstranded,/path/D5_1_R1.fq.gz,/path/D5_1_R2.fq.gz
D5_2,control,unstranded,/path/D5_2_R1.fq.gz,/path/D5_2_R2.fq.gz
D6_1,test,unstranded,/path/D6_1_R1.fq.gz,/path/D6_1_R2.fq.gz
```

Columns:
	
    •	sample: unique sample identifier
	•	group: experimental condition (used for DE and diffSplice)
	•	strandedness: library strandedness
	•	fastq1, fastq2: paired-end FASTQ files

### Run the pipeline
```bash
nextflow run main.nf \
  -profile wehi \
  --samplesheet my_samplesheet.csv \
  --star_index /path/to/star_index \
  --gtf /path/to/gencode.gtf \
  --outdir results
```

## Pipeline overview
```text
FASTQ
  ↓
Alignment (STAR / HISAT2)
  ↓
Isoform quantification (StringTie)
  ↓
AS event generation (SUPPA2)
  ↓
PSI / TPM calculation
  ↓
Differential splicing (SUPPA2 diffSplice)
```
A visual summary is available in flowchart.png.


## Directory structure
```text
ASBench/
├── assets/                  Sample sheets and QC configs
├── bin/                     Helper scripts (Python/R)
├── conf/                    Cluster and profile configs
├── demo/                    Small demo datasets
├── modules/                 Nextflow DSL2 modules
│   ├── align/               STAR/HISAT2 alignment
│   ├── quantify_isoform/    StringTie, RSEM, etc.
│   ├── as_event/            SUPPA2/MAJIQ modules
│   ├── de/                  Differential expression
│   ├── qc/                  QC steps (FastQC, MultiQC)
│   └── qc_metrics/          Junction accuracy metrics
├── scripts/                 Standalone analysis scripts
├── main.nf                  Main Nextflow workflow
├── nextflow.config          Global configuration
├── flowchart.png            Pipeline overview figure
└── README.md
```
### Key modules

**Alignment**

	•	modules/align/star.nf
	•	modules/align/hisat2.nf

**Isoform quantification**

	•	modules/quantify_isoform/stringtie_ballgown.nf

**Alternative splicing**

	•	modules/as_event/suppa2_events.nf
	•	modules/as_event/suppa2_psi.nf
	•	modules/as_event/suppa2_diffsplice.nf
	•	modules/as_event/majiq_build.nf
	•	modules/as_event/majiq_psi.nf

**Differential expression**

	•	modules/de/deseq2.nf
	•	modules/de/edger_ql.nf
	•	modules/de/limma_voom.nf

## Results structure
Example output directory:
```text
results/
├── 02_align/
│   └── star/
├── 03_quant/
│   └── stringtie/
├── 05_as/
│   └── suppa2/
│       ├── events/
│       ├── psi/
│       └── diffsplice/
```
Subdirectories:

	•	events/: merged AS event definitions (*.ioe)
	•	psi/: per-sample PSI and TPM files
	•	diffsplice/: differential splicing results

### Standalone scripts
Located in bin/ and scripts/:

	•	bin/prepDE.py: StringTie to DE matrices
	•	bin/build_tpm_matrix.py: TPM matrix construction
	•	scripts/run_suppa2_diffsplice.py: standalone SUPPA2 diffSplice
	•	bin/junction_accuracy.py: splice junction benchmarking
	•	bin/run_junction_accuracy_nf.py: helper wrapper for junction accuracy

These can be used independently of Nextflow if needed.

### Profiles and HPC

Example Slurm profile:
```
-profile wehi
```

Defined in:

	•	conf/wehi_slurm.config

You can add additional profiles for other clusters.


**Common issues and notes**

	•	SUPPA2 diffSplice expects merged PSI/TPM matrices per condition
	•	Do not pass lists of per-sample files directly to suppa diffSplice
	•	For complex contrasts, prefer a standalone Python wrapper
	•	Always verify group labels in the samplesheet

## Citation

If you use ASBench, please cite the relevant tools:

	•	STAR
    •	Hisat2
	•	Cuffdiff
    •	Express
    •	RSEM
    •	StringTie
	•	SUPPA2
	•	MAJIQ
    •	edgeR
	•	Nextflow

## Contact

**Maintainer:**

Qingwang Chen: qwchen20@fudan.edu.cn

Duo Wang, 18801232285@163.com

**Project:** ASBench (Alternative Splicing Benchmarking)