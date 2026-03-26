process BUILD_MAJIQ_CONFIG {

    publishDir "${params.outdir}/04_as/majiq/config", mode: 'copy'

    input:
        tuple val(sample_id), val(group), path(bam)

    output:
        tuple val(sample_id), val(group), path("${sample_id}.majiq.ini")

    script:
    """
    set -euo pipefail

    python ${projectDir}/scripts/build_majiq_config.py \\
      --sample ${sample_id} \\
      --group ${group} \\
      --bam ${bam} \\
      --gtf ${params.gtf} \\
      --out ${sample_id}.majiq.ini
    """
}