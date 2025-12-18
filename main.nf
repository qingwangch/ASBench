nextflow.enable.dsl = 2

// ----------------------  imports  ----------------------
include { STAR_ALIGN }         from './modules/align/star'
include { STRINGTIE_BALLGOWN } from './modules/quantify_isoform/stringtie_ballgown'
include { SUPPA2_EVENTS }      from './modules/as_event/suppa2_events'
include { SUPPA2_PSI }         from './modules/as_event/suppa2_psi'
include { SUPPA2_MERGE_GROUP } from './modules/as_event/suppa2_merge_group'
include { SUPPA2_DIFFSPLICE }  from './modules/as_event/suppa2_diffsplice'

// ----------------------  params   ----------------------
params.samplesheet = params.samplesheet ?: null
params.outdir      = params.outdir      ?: "results"

params.star_index  = params.star_index  ?: null
params.gtf         = params.gtf         ?: null
params.star_mode   = params.star_mode   ?: "genome_geneCounts"

// ----------------------  workflow ----------------------
workflow {

    /* sanity-checks ---------------------------------------------------- */
    if( !params.samplesheet ) error "Missing --samplesheet"
    if( !params.star_index )  error "Missing --star_index"
    if( !params.gtf )         error "Missing --gtf"

    log.info "FASTQ → STAR → StringTie → SUPPA2"

    /* 1. samplesheet --------------------------------------------------- */
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

    /* 2. STAR ---------------------------------------------------------- */
    def (ch_star , _) = STAR_ALIGN( ch_reads )

    /* 3. StringTie ----------------------------------------------------- */
    def ch_st_in = ch_star.map{ s, g, strand, bam, sj, log, gc ->
                        tuple(s, g, strand, bam)      // only what module needs
                     }

    def ch_stringtie = STRINGTIE_BALLGOWN( ch_st_in )
                       .view{ it -> "✔ StringTie done for ${it[0]}" }

    /* 4. merged IOE ---------------------------------------------------- */
    def ch_ref_gtf   = Channel.value( file(params.gtf) )
    def ch_merged_ioe = SUPPA2_EVENTS( ch_ref_gtf ).map { dir -> file("${dir}/gencode.v43.all_AS.ioe") }

    /* 5. sample-level GTFs -------------------------------------------- */
    def ch_sample_gtf = ch_stringtie.map{ s, _g, _bg, gtf, _ga ->
                            tuple(s, gtf)                 // (sample , gtf)
                         }

    /* 6. PSI for every sample ----------------------------------------- */
    def ch_ev_sample = ch_merged_ioe.combine( ch_sample_gtf )

    def ch_psitpm = SUPPA2_PSI( ch_ev_sample )   // now: (sample, psi, tpm)

    /* 7. diffSplice between groups ------------------------------------- */
}