/* modules/as_event/suppa2_psi.nf
 * For one sample:
 *   1. convert its StringTie GTF to a single-column TPM table
 *   2. run SUPPA2 psiPerEvent for one merged IOE file
 *
 * input  : ( ioefile , sample_id , gtf_path )
 * output :  psi/<sample>_<evt>.psi
 *           <sample>_transcript_tpm.tsv
 */
process SUPPA2_PSI {

    tag { "${sample_id}:${ioe_file.baseName}" }

    publishDir "${params.outdir}/05_as/suppa2/psi", mode: 'copy'
    container  '/vast/projects/quartet_rna_refdata/images/suppa_2.4.sif'

    cpus   { params.threads_suppa2 ?: 4  }
    memory { params.mem_suppa2     ?: '8 GB' }
    time   { params.time_suppa2    ?: '2h'   }

    /* incoming tuple */
    input:
        tuple path(ioe_file), val(sample_id), path(gtf_file)

    output:
        tuple val(sample_id),
            path("psi/${sample_id}_${ioe_file.baseName}.psi"),
            path("${sample_id}_transcript_tpm.tsv")

    script:
    """
    set -euo pipefail
    mkdir -p psi

    # ---------- 1) build TPM table --------------------------------------
    python - <<'PY'
import re, csv, pathlib, sys
gtf    = "${gtf_file}"
sample = "${sample_id}"

rows = []
with open(gtf) as fh:
    for ln in fh:
        if ln.startswith('#') or 'TPM' not in ln:
            continue
        m_tid = re.search(r'transcript_id "([^"]+)"', ln)
        m_tpm = re.search(r'TPM "([^"]+)"',          ln)
        if m_tid and m_tpm:
            rows.append((m_tid.group(1), float(m_tpm.group(1))))

if not rows:
    sys.stderr.write(f"[WARN] No TPM tags found in {gtf}\\n")
    sys.exit(1)

out_name = f"{sample}_transcript_tpm.tsv"
with open(out_name, "w", newline="") as out:
    out.write(sample + "\\n")          # only sample ID on the first line
    wr = csv.writer(out, delimiter="\\t", lineterminator="\\n")
    wr.writerows(rows)
PY

    # ---------- 2) SUPPA2 psiPerEvent -----------------------------------
    suppa psiPerEvent \
        --ioe-file "${ioe_file}" \
        --expression-file "${sample_id}_transcript_tpm.tsv" \
        -o psi/${sample_id}_${ioe_file.baseName}
    """
}