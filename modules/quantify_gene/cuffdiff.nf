process CUFFDIFF_RUN {

    tag { "${group1}_vs_${group2}" }

    publishDir "${params.outdir}/04_de/cuffdiff/${group1}_vs_${group2}", mode: 'copy'

    input:
        tuple val(group1), path(group1_bams),
              val(group2), path(group2_bams),
              path(genome_fasta), path(gtf)

    output:
        path "*"

    script:
    def g1 = group1_bams.collect { it.toString() }.join(',')
    def g2 = group2_bams.collect { it.toString() }.join(',')

    """
    set -euo pipefail

    cuffdiff \
      -o cuffdiff_out \
      -b ${genome_fasta} \
      -u ${gtf} \
      ${gtf} \
      ${g1} ${g2}

    cp -r cuffdiff_out/* .
    """
}
