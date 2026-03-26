process MAJIQ_BUILD {

    tag { sample_id }

    publishDir "${params.outdir}/04_as/majiq/build/${sample_id}", mode: 'copy'

    input:
        tuple val(sample_id), val(group), path(majiq_ini)

    output:
        tuple val(sample_id), val(group), path("${sample_id}.majiq")

    script:
    """
    set -euo pipefail

    majiq build \\
      -j ${params.threads_majiq ?: 8} \\
      -o majiq_build \\
      -c ${majiq_ini} \\
      ${params.gtf}

    find majiq_build -name "*.majiq" | head -n 1 | xargs -I{} cp {} ${sample_id}.majiq
    """
}