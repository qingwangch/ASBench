nextflow.enable.dsl=2

process EDGER_QL {

  tag "edgeR_QL"
  publishDir "${params.outdir}/06_stats/edgeR_QL", mode: 'copy'

  conda "bioconda::r-base=4.4.1 bioconda::bioconductor-edger=4.4.2 bioconda::r-optparse=1.7.5"

  cpus   { params.threads_r ?: 4 }
  memory { params.mem_r     ?: '16 GB' }
  time   { params.time_r    ?: '2h' }

  input:
    path(counts_tsv)   // gene x sample, tab-delimited
    path(meta_tsv)     // columns: sample, group (test/control)

  output:
    path("edger_ql_results.tsv")
    path("edger_ql_results_DEG_summary.txt")

  script:
  """
  set -euo pipefail

  Rscript ${projectDir}/bin/edger_ql.R \\
    --counts ${counts_tsv} \\
    --meta ${meta_tsv} \\
    --out edger_ql_results.tsv
  """
}
