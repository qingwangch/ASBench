/* modules/as_event/suppa2_diffsplice.nf
 * -------------------------------------
 * Run SUPPA2 diffSplice using merged PSI/TPM matrices (per-group).
 *
 * INPUT tuple:
 *   ( cond1_name, cond1_psi_merged, cond1_tpm_merged,
 *     cond2_name, cond2_psi_merged, cond2_tpm_merged,
 *     ioe_file )
 */

nextflow.enable.dsl = 2

process SUPPA2_DIFFSPLICE {

  tag { "${cond1_name}_vs_${cond2_name}" }

  publishDir "${params.outdir}/05_as/suppa2/diffsplice/${cond1_name}_vs_${cond2_name}", mode: 'copy'

  container { params.suppa2_container ?: '/vast/projects/quartet_rna_refdata/images/suppa_2.4.sif' }

  cpus   { params.threads_suppa2 ?: 4 }
  memory { params.mem_suppa2     ?: '16 GB' }
  time   { params.time_suppa2    ?: '6h' }

  input:
    tuple val(cond1_name),
          path(cond1_psi),
          path(cond1_tpm),
          val(cond2_name),
          path(cond2_psi),
          path(cond2_tpm),
          path(ioe_file)

  output:
    path "${cond1_name}_vs_${cond2_name}.*",
    emit: diffsplice_out

  script:
    def method     = params.ds_method      ?: 'empirical'
    def area       = params.ds_area        ?: 1000
    def lowerBound = params.ds_lower_bound ?: 0.05
    def prefix     = "${cond1_name}_vs_${cond2_name}"

  """
  set -euo pipefail

  suppa diffSplice \\
    --method       ${method} \\
    --input        "${ioe_file}" \\
    --psi          "${cond1_psi}" "${cond2_psi}" \\
    --tpm          "${cond1_tpm}" "${cond2_tpm}" \\
    --area         ${area} \\
    --lower-bound  ${lowerBound} \\
    -gc \\
    -o             "${prefix}"
  """
}