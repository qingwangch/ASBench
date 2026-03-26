process MAJIQ_DELTAPSI {

    tag { "${group1}_vs_${group2}" }

    publishDir "${params.outdir}/05_as/majiq/${group1}_vs_${group2}", mode: 'copy'

    input:
        tuple val(group1), path(group1_majiq),
              val(group2), path(group2_majiq)

    output:
        path "*"

    script:
    def g1 = group1_majiq.collect { it.toString() }.join(' ')
    def g2 = group2_majiq.collect { it.toString() }.join(' ')

    """
    set -euo pipefail

    majiq deltapsi \\
      -j ${params.threads_majiq ?: 8} \\
      -o majiq_delta \\
      -n ${group1} ${group2} \\
      -grp1 ${g1} \\
      -grp2 ${g2}

    cp -r majiq_delta/* .
    """
}