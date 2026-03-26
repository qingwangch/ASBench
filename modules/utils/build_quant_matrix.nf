process BUILD_QUANT_MATRIX {

    tag "build_quant_matrix"

    publishDir "${params.outdir}/04_quant_matrix", mode: 'copy'

    input:
    tuple val(sample_ids), path(quant_files), val(groups)

    output:
    tuple path("quant_matrix.tsv"), path("sample_info.tsv")

    script:
    def samples = sample_ids.collect { "\"${it}\"" }.join(' ')
    def groups_str = groups.collect { "\"${it}\"" }.join(' ')
    def files = quant_files.collect { "\"${it}\"" }.join(' ')

    """
    python ${projectDir}/scripts/build_quant_matrix.py \
        --inputs ${files} \
        --samples ${samples} \
        --groups ${groups_str} \
        --out-matrix quant_matrix.tsv \
        --out-sample-info sample_info.tsv
    """
}
