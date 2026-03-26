process BUILD_GENE_COUNT_MATRIX {

    tag "build_gene_matrix"

    publishDir "${params.outdir}/04_gene_matrix", mode: 'copy'

    input:
    tuple val(sample_ids), path(count_files), val(groups)

    output:
    tuple path("gene_count_matrix.tsv"), path("sample_info.tsv")

    script:
    def samples = sample_ids.collect { "\"${it}\"" }.join(' ')
    def groups_str = groups.collect { "\"${it}\"" }.join(' ')
    def files = count_files.collect { "\"${it}\"" }.join(' ')

    """
    python ${projectDir}/scripts/build_gene_count_matrix.py \
        --inputs ${files} \
        --samples ${samples} \
        --groups ${groups_str} \
        --out-matrix gene_count_matrix.tsv \
        --out-sample-info sample_info.tsv
    """
}
