# ASBench

ASBench is a modular Nextflow DSL2 pipeline for benchmarking representative short-read RNA-seq analysis workflows for transcript quantification, differential expression, and alternative splicing.

The current first release supports five representative workflow combinations:

- `star_stringtie_suppa2`
- `hisat2_cuffdiff`
- `star_express_limma`
- `star_rsem_deseq2`
- `star_majiq`

> `star_majiq` is currently an initial implementation and may require additional MAJIQ-specific configuration depending on the runtime environment.

## Overview

ASBench provides a unified framework for running and comparing different combinations of:

- aligners
- quantification tools
- differential expression tools
- splicing analysis tools

The workflow is organized as reusable Nextflow DSL2 modules.

## Currently supported workflow combinations

### 1. `star_stringtie_suppa2`

```text
FASTQ
→ STAR (genome alignment + geneCounts)
→ StringTie / Ballgown
→ SUPPA2 event generation
→ sample-level PSI / TPM
→ group-level PSI / TPM merge
→ SUPPA2 diffSplice
```

### 2. `hisat2_cuffdiff`

```text
FASTQ
→ HISAT2
→ Cuffdiff
```

### 3. `star_express_limma`

```text
FASTQ
→ STAR (transcriptome mode)
→ eXpress
→ quant matrix construction
→ limma
```

### 4. `star_rsem_deseq2`

```text
FASTQ
→ STAR (transcriptome mode)
→ RSEM
→ quant matrix construction
→ DESeq2
```

### 5. `star_majiq`

```text
FASTQ
→ STAR (genome alignment)
→ MAJIQ config generation
→ MAJIQ build
→ MAJIQ deltapsi
```

## Repository structure

```text
ASBench/
├── assets/
│   └── samplesheet.template.csv
├── basic_qc/
├── basic_qc_parameters_and_cutoffs.md
├── bin/
├── conf/
│   └── modules.config
├── demo/
├── figures/
├── main.nf
├── nextflow.config
├── modules/
│   ├── align/
│   │   ├── star.nf
│   │   └── hisat2_cuffdiff.nf
│   ├── quantify_isoform/
│   │   ├── stringtie_ballgown.nf
│   │   ├── express.nf
│   │   └── rsem.nf
│   ├── quantify_gene/
│   │   └── cuffdiff.nf
│   ├── de/
│   │   ├── limma.nf
│   │   └── deseq2.nf
│   ├── as_event/
│   │   ├── suppa2_events.nf
│   │   ├── suppa2_psi.nf
│   │   ├── suppa2_merge_group.nf
│   │   ├── suppa2_diffsplice.nf
│   │   ├── majiq_build.nf
│   │   └── majiq_delta_psi.nf
│   └── utils/
│       ├── build_gene_count_matrix.nf
│       ├── build_quant_matrix.nf
│       └── build_majiq_config.nf
├── scripts/
│   ├── build_gene_count_matrix.py
│   ├── build_quant_matrix.py
│   ├── build_majiq_config.py
│   ├── run_deseq2.R
│   ├── run_limma.R
│   └── plot_qc_distribution.py
├── test.sh
└── README.md
```

## Requirements

- Nextflow (DSL2)
- Java 11+
- Apptainer / Singularity recommended
- Tool-specific dependencies available in containers or system environment:
  - STAR
  - HISAT2
  - StringTie
  - SUPPA2
  - eXpress
  - RSEM
  - Cuffdiff
  - MAJIQ
  - R with DESeq2 / limma / edgeR as needed

## Input samplesheet

Example template:

```csv
sample,group,strandedness,fastq1,fastq2
D5_1,control,unstranded,/path/D5_1_R1.fq.gz,/path/D5_1_R2.fq.gz
D5_2,control,unstranded,/path/D5_2_R1.fq.gz,/path/D5_2_R2.fq.gz
D6_1,test,unstranded,/path/D6_1_R1.fq.gz,/path/D6_1_R2.fq.gz
D6_2,test,unstranded,/path/D6_2_R1.fq.gz,/path/D6_2_R2.fq.gz
```

Columns:

- `sample`: unique sample ID
- `group`: biological condition / contrast group
- `strandedness`: library strandedness
- `fastq1`, `fastq2`: paired-end FASTQ files

## Usage

### General syntax

```bash
nextflow run main.nf   -profile wehi   --pipeline <pipeline_name>   --samplesheet assets/samplesheet.template.csv   --outdir results   [other pipeline-specific parameters]
```

### Pipeline-specific examples

#### 1. STAR + StringTie + SUPPA2

```bash
nextflow run main.nf   -profile wehi   --pipeline star_stringtie_suppa2   --samplesheet assets/samplesheet.template.csv   --star_index /path/to/star_index   --gtf /path/to/annotation.gtf   --outdir results
```

#### 2. HISAT2 + Cuffdiff

```bash
nextflow run main.nf   -profile wehi   --pipeline hisat2_cuffdiff   --samplesheet assets/samplesheet.template.csv   --hisat2_index /path/to/hisat2_index   --genome_fasta /path/to/genome.fa   --gtf /path/to/annotation.gtf   --outdir results
```

#### 3. STAR + eXpress + limma

```bash
nextflow run main.nf   -profile wehi   --pipeline star_express_limma   --samplesheet assets/samplesheet.template.csv   --star_index /path/to/star_index   --transcriptome_fasta /path/to/transcripts.fa   --outdir results
```

#### 4. STAR + RSEM + DESeq2

```bash
nextflow run main.nf   -profile wehi   --pipeline star_rsem_deseq2   --samplesheet assets/samplesheet.template.csv   --star_index /path/to/star_index   --rsem_index /path/to/rsem_reference   --outdir results
```

#### 5. STAR + MAJIQ

```bash
nextflow run main.nf   -profile wehi   --pipeline star_majiq   --samplesheet assets/samplesheet.template.csv   --star_index /path/to/star_index   --gtf /path/to/annotation.gtf   --outdir results
```

## Basic QC metrics, cutoffs, and visualization

ASBench can be used to summarize and visualize basic QC metrics for input sample(s) by combining:

- **FastQC**
- **FastQ Screen**
- **Qualimap**
- **RSeQC**
- **STAR-StringTie-SUPPA2-based SNR calculation**

### Basic QC metric categories

| Category | Metric | Source tool / workflow |
|---|---|---|
| Pre-alignment QC | Strand specificity | RSeQC |
| Pre-alignment QC | Number of Reads (million) | FastQC / FastQ Screen |
| Pre-alignment QC | Number of paired-end reads (million) | FastQC / FastQ Screen |
| Pre-alignment QC | Q30 (%) | FastQC |
| Pre-alignment QC | Q20 (%) | FastQC |
| Pre-alignment QC | GC (%) | FastQC |
| Pre-alignment QC | Paired-end reads length (bp) | FastQC |
| Pre-alignment QC | Duplicate rate (%) | FastQC / Qualimap |
| Post-alignment QC | Unique mapped (%) | Qualimap |
| Post-alignment QC | Unmapped (%) | Qualimap |
| Post-alignment QC | Multiple mapped (%) | Qualimap |
| Post-alignment QC | Total mapped (%) | Qualimap |
| Post-alignment QC | Mismatch bases rate (%) | Qualimap |
| Post-alignment QC | 5' - 3' bias | Qualimap / RSeQC |
| Post-alignment QC | Mapped to exonic region (%) | Qualimap |
| Post-alignment QC | Mapped to intronic region (%) | Qualimap |
| Post-alignment QC | Mapped to intergentic region (%) | Qualimap |
| SNR | Gene-level SNR | STAR-StringTie-SUPPA2 TPM/PSI-based analysis |
| SNR | Isoform-level SNR | STAR-StringTie-SUPPA2 TPM/PSI-based analysis |
| SNR | AS event-level SNR | STAR-StringTie-SUPPA2 TPM/PSI-based analysis |

### Example QC cutoff rules

| Metric | QC cutoff |
|---|---|
| Number of Reads (million) | `>20` |
| Number of paired-end reads (million) | `>85` |
| Q30 (%) | `>90` |
| Duplicate rate (%) | `<30` |
| Unique mapped (%) | `>80` |
| Total mapped (%) | `>90` |
| 5' - 3' bias | `0.8-1.2` |
| Mapped to intergentic region (%) | `<10` |
| Gene-level SNR | `>12` |
| Isoform-level SNR | `>10` |
| AS event-level SNR | `>10` |

### QC distribution plots

QC metric distributions can be visualized by plotting the input sample(s) against the 42-laboratory reference background.

If the generated figures are placed under `figures/`, they can be displayed directly in Markdown.

#### Pre-alignment QC
![Pre-alignment QC distribution](figures/qc_distribution_pre_alignment.png)

#### Post-alignment QC
![Post-alignment QC distribution](figures/qc_distribution_post_alignment.png)

#### SNR
![SNR distribution](figures/qc_distribution_snr.png)

### Plot generation example

```bash
python scripts/plot_qc_distribution.py   --baseline qc_baseline.tsv   --input-metrics basic_qc_metrics.tsv   --cutoffs qc_cutoffs.tsv   --outdir figures
```

### Full QC documentation

For the full QC metric definitions, reference distributions, cutoff table, and figure embedding template, see:

- `basic_qc_parameters_and_cutoffs.md`

## Main parameters

### Common

- `--pipeline`
- `--samplesheet`
- `--outdir`

### STAR-based workflows

- `--star_index`
- `--star_mode` (set internally in `main.nf` for supported workflows)

### HISAT2/Cuffdiff

- `--hisat2_index`
- `--genome_fasta`
- `--gtf`

### SUPPA2

- `--gtf`
- `--threads_suppa2`
- `--mem_suppa2`
- `--time_suppa2`

### eXpress

- `--transcriptome_fasta`

### RSEM

- `--rsem_index`

### MAJIQ

- `--gtf`
- `--threads_majiq`

## Output structure

Output depends on pipeline branch. Typical top-level structure:

```text
results/
├── 02_align/
├── 03_quant/
├── 04_matrix/
├── 05_de/
└── 05_as/
```

Examples:

### `star_stringtie_suppa2`

```text
02_align/star/
03_quant/stringtie/
05_as/suppa2/events/
05_as/suppa2/psi/
05_as/suppa2/merged/
05_as/suppa2/diffsplice/
```

### `star_express_limma`

```text
02_align/star/
03_quant/express/
04_quant_matrix/
05_de/limma/
```

### `star_rsem_deseq2`

```text
02_align/star/
03_quant/rsem/
04_quant_matrix/
05_de/deseq2/
```

## Notes and current limitations

- The current release is focused on a small number of representative workflow combinations rather than all possible tool combinations.
- `build_gene_count_matrix.nf` is currently included in the repository but not yet wired into a default branch in `main.nf`.
- MAJIQ support is currently an initial implementation and may require additional configuration depending on the environment.
- Some additional modules in the repository may still require refinement for production use.

## Contact

**Maintainer**

Qingwang Chen  
`qwchen20@fudan.edu.cn`

Duo Wang  
`18801232285@163.com`

Project: **ASBench (Alternative Splicing Benchmarking)**
