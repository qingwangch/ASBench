nextflow.enable.dsl=2

process LIMMA_TREND {

  tag "limma_trend"
  publishDir "${params.outdir}/06_stats/limma_trend", mode: 'copy'

  conda "bioconda::r-base=4.4.1 bioconda::bioconductor-limma=3.62.2 bioconda::bioconductor-edger=4.4.2 bioconda::r-optparse=1.7.5"

  cpus   { params.threads_r ?: 4 }
  memory { params.mem_r     ?: '16 GB' }
  time   { params.time_r    ?: '2h' }

  input:
    path(counts_tsv)
    path(meta_tsv)

  output:
    path("limma_trend_results.tsv")

  script:
  """
  set -euo pipefail

  Rscript ${projectDir}/bin/limma_voom.R \\
    --counts ${counts_tsv} \\
    --meta ${meta_tsv} \\
    --out limma_trend_results.tsv
  """
}
// vim:ft=nextflow