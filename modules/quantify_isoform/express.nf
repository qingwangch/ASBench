process EXPRESS_QUANT {

    tag { sample_id }

    publishDir "${params.outdir}/03_quant/express/${sample_id}", mode: 'copy'

    input:
        tuple val(sample_id), val(group), path(tx_bam)

    output:
        tuple val(sample_id), val(group), path("${sample_id}.xprs")

    script:
    """
    set -euo pipefail

    express ${params.transcriptome_fasta} ${tx_bam} -o ${sample_id}_express

    cp ${sample_id}_express/results.xprs ${sample_id}.xprs
    """
}