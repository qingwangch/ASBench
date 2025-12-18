/*
 * Generate alternative-splicing event files (IOE) with SUPPA2
 * ----------------------------------------------------------
 * Input : one GTF
 * Output:  events/<prefix>.AS_<TYPE>.ioe   (SE-/SS-/MX-/RI-/FL)
 *          events/<prefix>.all_AS.ioe      (merged without duplicate header)
 */
process SUPPA2_EVENTS {

    tag 'suppa2_events'
    publishDir "${params.outdir}/05_as/suppa2/events", mode:'copy'

    container '/vast/projects/quartet_rna_refdata/images/suppa_2.4.sif'

    cpus   { params.threads_suppa2 ?: 4 }
    memory { params.mem_suppa2     ?: '8 GB' }
    time   { params.time_suppa2    ?: '2h' }

    input:
        path gtf_file

    output:
        path "events"            // whole directory with *.ioe  +  merged file

    script:
    /*
       derive a clean prefix from the GTF file name, e.g.
       gencode_v43.chr_patch_hapl_scaff.annotation.gtf  ->  gencode_v43
    */
    def base = gtf_file.baseName
               .replaceAll(/\.gtf$/,'')
               .replaceAll(/\.annotation$/,'')
               .replaceAll(/\.chr.*$/,'')  // optional cleanup of long names

    """
    set -euo pipefail

    mkdir -p events

    # -------- 1. generate events per type --------
    suppa generateEvents \\
        -i ${gtf_file} \\
        -o events/${base}.AS \\
        -f ioe \\
        -e SE SS MX RI FL

    # -------- 2. merge into one all-AS file (keep single header) --------
    cat events/${base}.AS_*_strict.ioe | \\
        awk 'NR==1 || (\$0 !~ /^seqname/)' > events/${base}.all_AS.ioe
    """
}