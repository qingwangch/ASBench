process HISAT2_CUFFDIFF {

    tag { sample_id }

    publishDir "${params.outdir}/02_align/hisat2/${sample_id}", mode: 'copy'

    input:
        tuple val(sample_id), val(group), val(strandedness), path(fastq1), path(fastq2)

    output:
        tuple val(sample_id), val(group), path("${sample_id}.bam")

    script:
    """
    set -euo pipefail

    hisat2 \\
      -p ${params.threads_hisat2 ?: 8} \\
      -x ${params.hisat2_index} \\
      -1 ${fastq1} \\
      -2 ${fastq2} \\
      -S ${sample_id}.sam \\
      --dta-cufflinks

    samtools view -@ ${params.threads_hisat2 ?: 8} -bS ${sample_id}.sam | \\
      samtools sort -@ ${params.threads_hisat2 ?: 8} -o ${sample_id}.bam

    rm -f ${sample_id}.sam
    """
}