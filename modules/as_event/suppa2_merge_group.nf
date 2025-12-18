/* modules/as_event/suppa2_merge_group.nf
 * -------------------------------------
 * Merge per-sample PSI/TPM (2-col each) into per-group matrices.
 *
 * INPUT tuple:
 *   ( group_name, psi_files, tpm_files )
 *     - psi_files: path collection of *.psi (each has header line then: event<TAB>value)
 *     - tpm_files: path collection of TPM files (each has first line sampleID then: tx<TAB>value)
 *
 * OUTPUT tuple:
 *   ( group_name, merged_psi, merged_tpm )
 */

nextflow.enable.dsl = 2

process SUPPA2_MERGE_GROUP {

  tag { group_name }

  publishDir "${params.outdir}/05_as/suppa2/merged/${group_name}", mode: 'copy'

  container { params.suppa2_container ?: '/vast/projects/quartet_rna_refdata/images/suppa_2.4.sif' }

  cpus   { params.threads_suppa2 ?: 2 }
  memory { params.mem_suppa2     ?: '8 GB' }
  time   { params.time_suppa2    ?: '1h' }

  input:
    tuple val(group_name),
          path(psi_files),
          path(tpm_files)

  output:
    tuple val(group_name),
          path("${group_name}.merged.psi"),
          path("${group_name}.merged.tpm"),
          emit: merged_out

  script:
  """
  set -euo pipefail

  merge_by_key () {
    # Usage: merge_by_key <mode:psi|tpm> <out> <files...>
    mode="\$1"; out="\$2"; shift 2
    files=( "\$@" )
    [ "\${#files[@]}" -gt 0 ] || { echo "[ERROR] no input files for \$out" >&2; exit 1; }

    # header line: ONLY sample names
    if [ "\$mode" = "psi" ]; then
      hdr=\$(for f in "\${files[@]}"; do basename "\$f" .psi; done | paste -sd \$'\\t' -)
    else
      hdr=\$(for f in "\${files[@]}"; do head -n1 "\$f"; done | paste -sd \$'\\t' -)
    fi

    {
      echo -e "\$hdr"
      awk -F'\\t' -v OFS='\\t' '
        FNR==1 { filei++; next }      # skip first line of each file
        {
          k=\$1; v=\$2
          if(!(k in seen)){ seen[k]=1; ord[++n]=k }
          mat[k,filei]=v
        }
        END{
          for(i=1;i<=n;i++){
            k=ord[i]
            printf "%s", k
            for(j=1;j<=filei;j++){
              x=((k SUBSEP j) in mat)?mat[k,j]:"NA"
              printf OFS "%s", x
            }
            printf "\\n"
          }
        }
      ' "\${files[@]}"
    } > "\$out"
  }

  # PSI/TPM输入是“文件集合”，Nextflow会把它们stage到工作目录，这里直接用glob就行
  psi_list=( ${psi_files} )
  tpm_list=( ${tpm_files} )

  # 稳定排序，保证列顺序一致
  IFS=\$'\\n' psi_list=( \$(printf "%s\\n" "\${psi_list[@]}" | sort) )
  IFS=\$'\\n' tpm_list=( \$(printf "%s\\n" "\${tpm_list[@]}" | sort) )
  unset IFS

  merge_by_key psi "${group_name}.merged.psi" "\${psi_list[@]}"
  merge_by_key tpm "${group_name}.merged.tpm" "\${tpm_list[@]}"
  """
}