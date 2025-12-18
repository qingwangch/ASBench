process STAR_ALIGN {

  tag { sample }
  publishDir "${params.outdir}/02_align/star/${sample}", mode: 'copy'

  container '/vast/projects/quartet_rna_refdata/images/star_2.7.10b.sif'

  cpus   { params.threads_star ?: 16 }
  memory { params.mem_star     ?: '48 GB' }
  time   { params.time_star    ?: '24h' }

  input:
    tuple val(sample), val(group), val(strandedness), path(fq1), path(fq2)

  output:
    /* ---------- 1) the tuple with files that always exist ---------- */
    tuple val(sample), val(group), val(strandedness),
          path("${sample}.genome.bam"),
          path("SJ.out.tab"),
          path("Log.final.out"),
          path("ReadsPerGene.out.tab", optional: true)

    /* ---------- 2) transcriptome BAM: standalone & optional ---------- */
    path("${sample}.transcriptome.bam", optional: true)

  script:
  def mode = (params.star_mode ?: "genome_geneCounts").toString()

  // Common STAR arguments (matching your excel commands)
  def common = """
    --genomeDir ${params.star_index} \\
    --runThreadN ${task.cpus} \\
    --readFilesIn ${fq1} ${fq2} \\
    --readFilesCommand zcat \\
    --outFileNamePrefix ${sample}. \\
    --outSAMtype BAM SortedByCoordinate \\
    --outSAMattributes All \\
    --twopassMode Basic
  """.stripIndent().trim()

  // Mode-specific args (exactly aligned to what you wrote)
  def modeArgs = ""
  if( mode == "genome_geneCounts" ) {
    modeArgs = "--quantMode GeneCounts"
  } else if( mode == "transcriptome_express" ) {
    modeArgs = """
      --quantMode TranscriptomeSAM \\
      --quantTranscriptomeBan Singleend
    """.stripIndent().trim()
  } else if( mode == "genome_cuffdiff" ) {
    modeArgs = """
      --quantMode GeneCounts \\
      --outSAMunmapped Within \\
      --outSAMstrandField intronMotif \\
      --outFilterIntronMotifs RemoveNoncanonical
    """.stripIndent().trim()
  } else {
    throw new IllegalArgumentException("Unsupported --star_mode='${mode}'. Use: genome_geneCounts | transcriptome_express | genome_cuffdiff")
  }

  """
  set -euo pipefail

  STAR \\
    ${common} \\
    ${modeArgs}

  # Standardize filenames
  mv ${sample}.Aligned.sortedByCoord.out.bam ${sample}.genome.bam
  mv ${sample}.SJ.out.tab SJ.out.tab
  mv ${sample}.Log.final.out Log.final.out

  # ReadsPerGene is only produced when GeneCounts is enabled
  if [ -f "${sample}.ReadsPerGene.out.tab" ]; then
    mv ${sample}.ReadsPerGene.out.tab ReadsPerGene.out.tab
  fi

  # Transcriptome BAM is only produced when TranscriptomeSAM is enabled
  if [ -f "${sample}.Aligned.toTranscriptome.out.bam" ]; then
    mv ${sample}.Aligned.toTranscriptome.out.bam ${sample}.transcriptome.bam
  fi
  """
}
