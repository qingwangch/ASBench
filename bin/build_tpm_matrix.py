/*
 * Merge StringTie t_data.ctab files into a transcript-level TPM matrix
 * -------------------------------------------------------------------
 * Input : list of ballgown/<sample> folders (collect:true)
 * Output: transcript_tpm.tsv
 */
process BUILD_TPM {

    tag 'build_tpm'
    publishDir "${params.outdir}/03_quant/stringtie_tpm", mode: 'copy'

    container '/vast/projects/quartet_rna_refdata/images/python311.sif'
    // 或用 conda "bioconda::python=3.11"

    input:
        path bg_dirs collect:true

    output:
        path 'transcript_tpm.tsv'

    script:
    """
    set -euo pipefail
    python ${projectDir}/bin/build_tpm_matrix.py \\
           --ballgown-dirs ${bg_dirs.join(' ')} \\
           --out transcript_tpm.tsv
    """
}