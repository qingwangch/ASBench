process RUN_DESEQ2 {

    publishDir "${params.outdir}/05_de/deseq2", mode: 'copy'

    input:
        tuple path(count_matrix), path(sample_info)

    output:
        path "deseq2_results.tsv"

    script:
    """
    set -euo pipefail
    Rscript ${projectDir}/scripts/run_deseq2.R ${count_matrix} ${sample_info} deseq2_results.tsv
    """
}