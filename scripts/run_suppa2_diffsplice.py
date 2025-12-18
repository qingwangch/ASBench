#!/usr/bin/env python3
import argparse
import os
import subprocess
from collections import OrderedDict, defaultdict

def read_two_col(path):
    """Read 2-col file (skip first line), return OrderedDict key->value(str)."""
    data = OrderedDict()
    with open(path, "r") as f:
        first = True
        for line in f:
            line = line.rstrip("\n")
            if not line:
                continue
            if first:
                first = False
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            k, v = parts[0], parts[1]
            if k not in data:
                data[k] = v
    return data

def read_header_sample(path, mode):
    """PSI: sample name from basename; TPM: sample name from first line."""
    if mode == "psi":
        base = os.path.basename(path)
        return base[:-4] if base.endswith(".psi") else base
    else:
        with open(path, "r") as f:
            return f.readline().rstrip("\n").split("\t")[0]

def merge_group(mode, out_path, in_files):
    """
    Merge many per-sample 2-col files -> matrix
    Output format:
      header: sample1<TAB>sample2...
      key<TAB>v1<TAB>v2...
    Missing value => NA
    """
    if len(in_files) == 0:
        raise ValueError(f"Empty input list for {out_path}")

    # stable column order
    in_files = sorted(in_files)

    samples = [read_header_sample(p, mode) for p in in_files]

    # collect all keys preserving first-seen order
    keys_order = []
    seen = set()
    per_file = []
    for p in in_files:
        d = read_two_col(p)
        per_file.append(d)
        for k in d.keys():
            if k not in seen:
                seen.add(k)
                keys_order.append(k)

    with open(out_path, "w") as out:
        out.write("\t".join(samples) + "\n")
        for k in keys_order:
            row = [k]
            for d in per_file:
                row.append(d.get(k, "NA"))
            out.write("\t".join(row) + "\n")

def run_cmd(cmd):
    p = subprocess.run(cmd, shell=False, check=False, text=True,
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return p.returncode, p.stdout

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ioe", required=True, help="Merged events .ioe")
    ap.add_argument("--cond1", required=True, help="Condition1 name (e.g. D6)")
    ap.add_argument("--cond2", required=True, help="Condition2 name (e.g. D5)")
    ap.add_argument("--cond1-psi", nargs="+", required=True, help="Per-sample PSI files (2-col) for cond1")
    ap.add_argument("--cond2-psi", nargs="+", required=True, help="Per-sample PSI files (2-col) for cond2")
    ap.add_argument("--cond1-tpm", nargs="+", required=True, help="Per-sample TPM files (2-col, first line sample) for cond1")
    ap.add_argument("--cond2-tpm", nargs="+", required=True, help="Per-sample TPM files (2-col, first line sample) for cond2")
    ap.add_argument("-o", "--outprefix", required=True, help="Output prefix (e.g. D6vD5)")
    ap.add_argument("--method", default="empirical")
    ap.add_argument("--area", type=int, default=1000)
    ap.add_argument("--lower-bound", type=float, default=0.05)
    ap.add_argument("--gc", action="store_true", default=True)
    ap.add_argument("--suppa", default="suppa", help="suppa executable in PATH")
    args = ap.parse_args()

    outdir = os.path.dirname(os.path.abspath(args.outprefix))
    if outdir and not os.path.exists(outdir):
        os.makedirs(outdir, exist_ok=True)

    c1_psi_m = args.outprefix + f".{args.cond1}.merged.psi"
    c2_psi_m = args.outprefix + f".{args.cond2}.merged.psi"
    c1_tpm_m = args.outprefix + f".{args.cond1}.merged.tpm"
    c2_tpm_m = args.outprefix + f".{args.cond2}.merged.tpm"

    merge_group("psi", c1_psi_m, args.cond1_psi)
    merge_group("psi", c2_psi_m, args.cond2_psi)
    merge_group("tpm", c1_tpm_m, args.cond1_tpm)
    merge_group("tpm", c2_tpm_m, args.cond2_tpm)

    cmd = [
        args.suppa, "diffSplice",
        "--method", str(args.method),
        "--input", args.ioe,
        "--psi", c1_psi_m, c2_psi_m,
        "--tpm", c1_tpm_m, c2_tpm_m,
        "--area", str(args.area),
        "--lower-bound", str(args.lower_bound),
    ]
    if args.gc:
        cmd.append("-gc")
    cmd += ["-o", args.outprefix]

    rc, out = run_cmd(cmd)
    print(out)
    if rc != 0:
        raise SystemExit(rc)

if __name__ == "__main__":
    main()