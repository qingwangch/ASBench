process RMATS {

    tag "${group1}_vs_${group2}"

    publishDir "${params.outdir}/05_as/rmats/${group1}_vs_${group2}", mode: 'copy'

    container params.rmats_container

    cpus   { params.rmats_threads ?: 8 }
    memory { params.rmats_memory  ?: '32 GB' }
    time   { params.rmats_time    ?: '12h' }

    input:
    tuple val(group1), val(bams1), val(group2), val(bams2)
    path gtf

    output:
    path "${group1}_vs_${group2}", emit: rmats_dir

    script:
    def readLength = params.rmats_read_length ?: 150
    def libType    = params.rmats_lib_type ?: 'fr-unstranded'
    def novelSS    = params.rmats_novel_ss ?: false
    def allowClips = params.rmats_allow_clipping ?: false
    def variableRL = params.rmats_variable_read_length ?: false
    def task       = params.rmats_task ?: 'both'
    def tmpdir     = "./tmp"
    def outdir     = "${group1}_vs_${group2}"

    def novelArg = novelSS ? "--novelSS 1" : ""
    def clipArg  = allowClips ? "--allow-clipping" : ""
    def varRlArg = variableRL ? "--variable-read-length" : ""

    /*
     * rMATS requires b1/b2 as text files containing comma-separated BAM paths.
     * main.nf currently passes BAM lists directly, so we write them here.
     */
    def b1Line = bams1.collect { it.toString() }.join(',')
    def b2Line = bams2.collect { it.toString() }.join(',')

    """
    set -euo pipefail

    mkdir -p "${tmpdir}"
    mkdir -p "${outdir}"

    cat > b1.txt <<EOF
${b1Line}
EOF

    cat > b2.txt <<EOF
${b2Line}
EOF

    rmats.py \\
      --b1 b1.txt \\
      --b2 b2.txt \\
      --gtf "${gtf}" \\
      --od "${outdir}" \\
      --tmp "${tmpdir}" \\
      --readLength ${readLength} \\
      --libType ${libType} \\
      --nthread ${params.rmats_threads ?: 8} \\
      --t paired \\
      --task ${task} \\
      ${novelArg} \\
      ${clipArg} \\
      ${varRlArg}
    """
}