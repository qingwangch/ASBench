#!/usr/bin/env python3

import argparse
from collections import OrderedDict
import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build quantification matrix from eXpress or RSEM result files"
    )
    parser.add_argument(
        "--inputs",
        nargs="+",
        required=True,
        help="Input quantification files (eXpress .xprs, RSEM *.genes.results, or *.isoforms.results)"
    )
    parser.add_argument(
        "--samples",
        nargs="+",
        required=True,
        help="Sample IDs, same order as --inputs"
    )
    parser.add_argument(
        "--groups",
        nargs="+",
        required=True,
        help="Group labels, same order as --inputs"
    )
    parser.add_argument(
        "--value-column",
        default=None,
        help="Value column to extract (e.g. est_counts, tpm, expected_count, TPM). If omitted, auto-select."
    )
    parser.add_argument(
        "--id-column",
        default=None,
        help="ID column to use. If omitted, auto-select."
    )
    parser.add_argument(
        "--out-matrix",
        required=True,
        help="Output quant matrix TSV"
    )
    parser.add_argument(
        "--out-sample-info",
        required=True,
        help="Output sample_info TSV"
    )
    return parser.parse_args()


def detect_format(df: pd.DataFrame) -> str:
    cols = set(df.columns)

    if {"target_id", "est_counts"}.issubset(cols):
        return "express"
    if {"gene_id", "expected_count"}.issubset(cols):
        return "rsem_gene"
    if {"transcript_id", "expected_count"}.issubset(cols):
        return "rsem_isoform"

    raise ValueError(f"Unable to detect quantification format from columns: {list(df.columns)}")


def choose_columns(df: pd.DataFrame, fmt: str, user_id_col: str = None, user_value_col: str = None):
    if user_id_col is not None:
        id_col = user_id_col
    else:
        if fmt == "express":
            id_col = "target_id"
        elif fmt == "rsem_gene":
            id_col = "gene_id"
        elif fmt == "rsem_isoform":
            id_col = "transcript_id"
        else:
            raise ValueError(f"Unsupported format: {fmt}")

    if user_value_col is not None:
        value_col = user_value_col
    else:
        if fmt == "express":
            value_col = "est_counts"
        elif fmt in {"rsem_gene", "rsem_isoform"}:
            value_col = "expected_count"
        else:
            raise ValueError(f"Unsupported format: {fmt}")

    if id_col not in df.columns:
        raise ValueError(f"ID column '{id_col}' not found in file. Available: {list(df.columns)}")
    if value_col not in df.columns:
        raise ValueError(f"Value column '{value_col}' not found in file. Available: {list(df.columns)}")

    return id_col, value_col


def read_quant_file(file_path: str, id_col: str = None, value_col: str = None) -> OrderedDict:
    df = pd.read_csv(file_path, sep="\t", comment="#")
    fmt = detect_format(df)
    chosen_id, chosen_value = choose_columns(df, fmt, id_col, value_col)

    out = OrderedDict()
    for _, row in df.iterrows():
        feat_id = row[chosen_id]
        value = row[chosen_value]

        try:
            out[str(feat_id)] = float(value)
        except Exception:
            out[str(feat_id)] = 0.0

    return out


def main():
    args = parse_args()

    if not (len(args.inputs) == len(args.samples) == len(args.groups)):
        raise ValueError("--inputs, --samples, and --groups must have the same length")

    all_ids = []
    seen = set()
    sample_dicts = {}

    for in_file, sample in zip(args.inputs, args.samples):
        values = read_quant_file(
            in_file,
            id_col=args.id_column,
            value_col=args.value_column
        )
        sample_dicts[sample] = values
        for feat_id in values.keys():
            if feat_id not in seen:
                seen.add(feat_id)
                all_ids.append(feat_id)

    matrix = pd.DataFrame(index=all_ids)

    for sample in args.samples:
        values = sample_dicts[sample]
        matrix[sample] = [values.get(feat_id, 0.0) for feat_id in all_ids]

    matrix.to_csv(args.out_matrix, sep="\t")

    sample_info = pd.DataFrame({
        "sample": args.samples,
        "group": args.groups
    })
    sample_info.to_csv(args.out_sample_info, sep="\t", index=False)


if __name__ == "__main__":
    main()