process RSEM_QUANT {

    tag { sample_id }

    publishDir "${params.outdir}/03_quant/rsem/${sample_id}", mode: 'copy'

    input:
        tuple val(sample_id), val(group), path(tx_bam)

    output:
        tuple val(sample_id), val(group), path("${sample_id}.genes.results"), path("${sample_id}.isoforms.results")

    script:
    """
    set -euo pipefail

    rsem-calculate-expression \\
      -p ${params.threads_rsem ?: 8} \\
      --star \\
      --no-bam-output \\
      --paired-end \\
      ${tx_bam} \\
      ${params.rsem_index} \\
      ${sample_id}
    """
}