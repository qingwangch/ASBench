/*
 *  Build gene / transcript count matrices from StringTie results
 *  ------------------------------------------------------------
 *  Input  : every  ballgown/<sample>/   directory (collected)
 *  Output : sample_lst.txt • gene_count_matrix.csv • transcript_count_matrix.csv
 */
process PREPDE {

    tag 'prepDE'
    publishDir "${params.outdir}/04_expression/prepDE", mode: 'copy'

    /* Use either a local Singularity image or keep the Conda line */
    //container '/vast/projects/quartet_rna_refdata/images/python311.sif'
    conda      "bioconda::python=3.11"

    cpus    1
    memory  '4 GB'
    time    '1h'

    /*
     * Nextflow will stage each ballgown/<sample> dir, then give us a *list*
     * variable `bg_dirs`.  `collect:true` makes it a single input group.
     */
    input:
        path bg_dirs collect: true

    output:
        path 'sample_lst.txt'
        path 'gene_count_matrix.csv'
        path 'transcript_count_matrix.csv'

    script:
    """
    set -euo pipefail

    # ---------- sanity check: path to prepDE.py ----------
    if [[ -z "${params.prepde_py:-}" ]]; then
        echo '[prepDE] ERROR: --prepde_py not provided' >&2
        exit 1
    fi
    if [[ ! -s "${params.prepde_py}" ]]; then
        echo "[prepDE] ERROR: prepDE.py not found at ${params.prepde_py}" >&2
        exit 1
    fi

    # ---------- build sample list ----------
    > sample_lst.txt    # truncate if exists
    for d in ${bg_dirs}; do
        # d looks like:  ballgown/<SAMPLE>
        sample=\$(basename "\$d")
        printf '%s\t%s\n' "\$sample" "\$d" >> sample_lst.txt
    done
    echo "[prepDE] sample list written with \$(wc -l < sample_lst.txt) entries"

    # ---------- run prepDE.py ----------
    python "${params.prepde_py}" -i sample_lst.txt

    # ---------- verify outputs ----------
    [[ -s gene_count_matrix.csv ]]        # abort if missing
    [[ -s transcript_count_matrix.csv ]]
    echo "[prepDE] finished OK"
    """
}