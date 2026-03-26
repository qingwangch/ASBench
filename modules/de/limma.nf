process RUN_LIMMA {

    publishDir "${params.outdir}/05_de/limma", mode: 'copy'

    input:
        tuple path(count_matrix), path(sample_info)

    output:
        path "limma_results.tsv"

    script:
    """
    set -euo pipefail
    Rscript ${projectDir}/scripts/run_limma.R ${count_matrix} ${sample_info} limma_results.tsv
    """
}