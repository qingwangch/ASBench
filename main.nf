nextflow.enable.dsl = 2

// ---------------------- imports ----------------------
include { STAR_ALIGN }              from './modules/align/star'
include { HISAT2_CUFFDIFF }         from './modules/align/hisat2_cuffdiff'

include { STRINGTIE_BALLGOWN }      from './modules/quantify_isoform/stringtie_ballgown'
include { EXPRESS_QUANT }           from './modules/quantify_isoform/express'
include { RSEM_QUANT }              from './modules/quantify_isoform/rsem'
include { CUFFDIFF_RUN }            from './modules/quantify_gene/cuffdiff'

include { SUPPA2_EVENTS }           from './modules/as_event/suppa2_events'
include { SUPPA2_PSI }              from './modules/as_event/suppa2_psi'
include { SUPPA2_MERGE_GROUP }      from './modules/as_event/suppa2_merge_group'
include { SUPPA2_DIFFSPLICE }       from './modules/as_event/suppa2_diffsplice'
include { MAJIQ_BUILD }             from './modules/as_event/majiq_build'
include { MAJIQ_DELTAPSI }          from './modules/as_event/majiq_delta_psi'

include { BUILD_GENE_COUNT_MATRIX } from './modules/utils/build_gene_count_matrix'
include { BUILD_QUANT_MATRIX }      from './modules/utils/build_quant_matrix'
include { BUILD_MAJIQ_CONFIG }      from './modules/utils/build_majiq_config'

include { RUN_LIMMA }               from './modules/de/limma'
include { RUN_DESEQ2 }              from './modules/de/deseq2'

// ---------------------- params -----------------------
params.samplesheet = params.samplesheet ?: null
params.outdir      = params.outdir      ?: "results"

params.pipeline    = params.pipeline    ?: null

params.star_index          = params.star_index ?: null
params.hisat2_index        = params.hisat2_index ?: null
params.rsem_index          = params.rsem_index ?: null
params.transcriptome_fasta = params.transcriptome_fasta ?: null
params.genome_fasta        = params.genome_fasta ?: null
params.gtf                 = params.gtf ?: null
params.majiq_ini           = params.majiq_ini ?: null

params.star_mode           = params.star_mode ?: "genome_geneCounts"

params.threads_star        = params.threads_star ?: 8
params.threads_stringtie   = params.threads_stringtie ?: 8
params.threads_suppa2      = params.threads_suppa2 ?: 8
params.threads_hisat2      = params.threads_hisat2 ?: 8
params.threads_rsem        = params.threads_rsem ?: 8
params.threads_majiq       = params.threads_majiq ?: 8

params.mem_suppa2          = params.mem_suppa2 ?: '16 GB'
params.time_suppa2         = params.time_suppa2 ?: '6h'

// ---------------------- workflow ---------------------
workflow {

    if( !params.samplesheet ) error "Missing --samplesheet"
    if( !params.pipeline )    error "Missing --pipeline"

    log.info "Running pipeline: ${params.pipeline}"

    /* 1. samplesheet */
    Channel
        .fromPath(params.samplesheet)
        .ifEmpty { error "Samplesheet not found: ${params.samplesheet}" }
        .splitCsv(header:true)
        .map { row ->
            tuple(
                row.sample.trim(),
                row.group.trim(),
                row.strandedness ? row.strandedness.trim() : 'unstranded',
                file(row.fastq1.trim()),
                file(row.fastq2.trim())
            )
        }
        .set { ch_reads }

    /*
     * Pipeline 1
     * star_genome + stringtie + suppa2
     */
    if( params.pipeline == 'star_stringtie_suppa2' ) {

        if( !params.star_index ) error "Missing --star_index"
        if( !params.gtf )        error "Missing --gtf"

        params.star_mode = 'genome_geneCounts'

        def (ch_star_main, ch_star_txbam) = STAR_ALIGN(ch_reads)

        def ch_st_in = ch_star_main.map { s, g, strand, bam, sj, log, gc ->
            tuple(s, g, strand, bam)
        }

        def ch_stringtie = STRINGTIE_BALLGOWN(ch_st_in)
            .view { it -> "✔ StringTie done for ${it[0]}" }

        def ch_ref_gtf = Channel.value(file(params.gtf))

        def ch_merged_ioe = SUPPA2_EVENTS(ch_ref_gtf)
            .map { dir -> file("${dir}/gencode.v43.all_AS.ioe") }

        def ch_sample_gtf = ch_stringtie.map { s, g, bg_dir, gtf, gene_abund ->
            tuple(s, gtf)
        }

        def ch_ev_sample = ch_merged_ioe.combine(ch_sample_gtf)

        // expected output from existing SUPPA2_PSI:
        // (sample, psi_file, tpm_file)
        def ch_psitpm = SUPPA2_PSI(ch_ev_sample)

        def ch_sample_group = ch_reads.map { s, g, strand, r1, r2 ->
            tuple(s, g)
        }

        def ch_group_lists = ch_sample_group
            .join(ch_psitpm)
            .map { s, g, psi, tpm -> tuple(g, psi, tpm) }
            .groupTuple()
            .map { g, rows ->
                tuple(
                    g,
                    rows.collect { it[0] },
                    rows.collect { it[1] }
                )
            }

        def ch_group_merged = SUPPA2_MERGE_GROUP(ch_group_lists)

        def ch_diff_input = ch_group_merged
            .collect()
            .combine(ch_merged_ioe)
            .map { groups, ioe ->

                if( groups.size() != 2 ) {
                    error "Need exactly 2 groups for diffSplice, got: ${groups.collect{ it[0] }}"
                }

                groups = groups.sort { a, b -> a[0] <=> b[0] }

                def c1 = groups[0]
                def c2 = groups[1]

                tuple(
                    c1[0], c1[1], c1[2],
                    c2[0], c2[1], c2[2],
                    ioe
                )
            }

        SUPPA2_DIFFSPLICE(ch_diff_input)
    }

    /*
     * Pipeline 2
     * hisat2_cuffdiff + cuffdiff
     */
    else if( params.pipeline == 'hisat2_cuffdiff' ) {

        if( !params.hisat2_index ) error "Missing --hisat2_index"
        if( !params.gtf )          error "Missing --gtf"
        if( !params.genome_fasta ) error "Missing --genome_fasta"

        def ch_bam = HISAT2_CUFFDIFF(ch_reads)

        def ch_group_bams = ch_bam
            .map { s, g, bam -> tuple(g, bam) }
            .groupTuple()
            .map { g, bams -> tuple(g, bams) }

        def ch_cuffdiff_input = ch_group_bams
            .collect()
            .map { groups ->
                if( groups.size() != 2 ) {
                    error "Need exactly 2 groups for cuffdiff, got: ${groups.collect{ it[0] }}"
                }

                groups = groups.sort { a, b -> a[0] <=> b[0] }

                def c1 = groups[0]
                def c2 = groups[1]

                tuple(
                    c1[0], c1[1],
                    c2[0], c2[1],
                    file(params.genome_fasta),
                    file(params.gtf)
                )
            }

        CUFFDIFF_RUN(ch_cuffdiff_input)
    }

    /*
     * Pipeline 3
     * star_transcriptome + express + limma
     */
    else if( params.pipeline == 'star_express_limma' ) {

        if( !params.star_index )          error "Missing --star_index"
        if( !params.transcriptome_fasta ) error "Missing --transcriptome_fasta"

        params.star_mode = 'transcriptome_express'

        def (ch_star_main, ch_star_txbam) = STAR_ALIGN(ch_reads)

        def ch_tx_input = ch_reads
            .join(
                ch_star_txbam.map { txbam ->
                    def sample = txbam.baseName.replaceFirst(/\.transcriptome$/, '')
                    tuple(sample, txbam)
                }
            )
            .map { s, g, strand, r1, r2, txbam ->
                tuple(s, g, txbam)
            }

        def ch_express = EXPRESS_QUANT(ch_tx_input)

        def ch_quant_input = ch_express
            .map { s, g, xprs -> tuple(s, xprs, g) }
            .collect()
            .map { rows ->
                tuple(
                    rows.collect { it[0] },   // sample_ids
                    rows.collect { it[1] },   // quant_files
                    rows.collect { it[2] }    // groups
                )
            }

        def ch_quant_matrix = BUILD_QUANT_MATRIX(ch_quant_input)
        RUN_LIMMA(ch_quant_matrix)
    }

    /*
     * Pipeline 4
     * star_transcriptome + rsem + deseq2
     */
    else if( params.pipeline == 'star_rsem_deseq2' ) {

        if( !params.star_index ) error "Missing --star_index"
        if( !params.rsem_index ) error "Missing --rsem_index"

        params.star_mode = 'transcriptome_express'

        def (ch_star_main, ch_star_txbam) = STAR_ALIGN(ch_reads)

        def ch_tx_input = ch_reads
            .join(
                ch_star_txbam.map { txbam ->
                    def sample = txbam.baseName.replaceFirst(/\.transcriptome$/, '')
                    tuple(sample, txbam)
                }
            )
            .map { s, g, strand, r1, r2, txbam ->
                tuple(s, g, txbam)
            }

        def ch_rsem = RSEM_QUANT(ch_tx_input)

        def ch_quant_input = ch_rsem
            .map { s, g, genes_res, isoforms_res -> tuple(s, genes_res, g) }
            .collect()
            .map { rows ->
                tuple(
                    rows.collect { it[0] },   // sample_ids
                    rows.collect { it[1] },   // quant_files
                    rows.collect { it[2] }    // groups
                )
            }

        def ch_quant_matrix = BUILD_QUANT_MATRIX(ch_quant_input)
        RUN_DESEQ2(ch_quant_matrix)
    }

    /*
     * Pipeline 5
     * star_genome + majiq
     */
    else if( params.pipeline == 'star_majiq' ) {

        if( !params.star_index ) error "Missing --star_index"
        if( !params.gtf )        error "Missing --gtf"

        params.star_mode = 'genome_geneCounts'

        def (ch_star_main, ch_star_txbam) = STAR_ALIGN(ch_reads)

        def ch_bam_only = ch_star_main.map { s, g, strand, bam, sj, log, gc ->
            tuple(s, g, bam)
        }

        def ch_majiq_cfg = BUILD_MAJIQ_CONFIG(ch_bam_only)
        def ch_majiq_bld = MAJIQ_BUILD(ch_majiq_cfg)

        def ch_majiq_group = ch_majiq_bld
            .map { s, g, majiq_file -> tuple(g, majiq_file) }
            .groupTuple()
            .collect()
            .map { groups ->

                if( groups.size() != 2 ) {
                    error "Need exactly 2 groups for MAJIQ, got: ${groups.collect{ it[0] }}"
                }

                groups = groups.sort { a, b -> a[0] <=> b[0] }

                def c1 = groups[0]
                def c2 = groups[1]

                tuple(c1[0], c1[1], c2[0], c2[1])
            }

        MAJIQ_DELTAPSI(ch_majiq_group)
    }

    else {
        error "Unsupported pipeline: ${params.pipeline}"
    }
}
