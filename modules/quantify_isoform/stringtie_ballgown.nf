process STRINGTIE_BALLGOWN {

  tag { sample }
  publishDir "${params.outdir}/03_quant/stringtie/${sample}", mode: 'copy'

  container '/vast/projects/quartet_rna_refdata/images/stringtie2_latest.sif'

  cpus   { params.threads_stringtie ?: 8 }
  memory { params.mem_stringtie     ?: '24 GB' }
  time   { params.time_stringtie    ?: '6h' }

  input:
  tuple val(sample), val(group), val(strandedness), path(genome_bam)
  
  output:
    tuple val(sample), val(group),
      path("ballgown/${sample}"),
      path("${sample}.gtf"),
      path("${sample}.gene_abund.tsv")

  script:
  def libFlag = strandedness == "rf" ? "--rf" : (strandedness == "fr" ? "--fr" : "")
  """
  set -euo pipefail

  mkdir -p ballgown

  stringtie ${genome_bam} \\
    -p ${task.cpus} \\
    -G ${params.gtf} \\
    -e -b ballgown/${sample} ${libFlag} \\
    -o ${sample}.gtf \\
    -A ${sample}.gene_abund.tsv
  """
}
