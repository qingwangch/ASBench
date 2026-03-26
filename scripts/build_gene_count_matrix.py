#!/usr/bin/env python3

import argparse
import os
from collections import OrderedDict
import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser(
        description="Build gene count matrix from STAR ReadsPerGene.out.tab files"
    )
    parser.add_argument(
        "--inputs",
        nargs="+",
        required=True,
        help="STAR ReadsPerGene.out.tab files"
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
        "--column",
        type=int,
        default=2,
        choices=[2, 3, 4],
        help="Column to use from ReadsPerGene.out.tab: 2=unstranded, 3=forward, 4=reverse (default: 2)"
    )
    parser.add_argument(
        "--out-matrix",
        required=True,
        help="Output count matrix TSV"
    )
    parser.add_argument(
        "--out-sample-info",
        required=True,
        help="Output sample_info TSV"
    )
    return parser.parse_args()


def read_star_gene_counts(file_path: str, count_col: int) -> OrderedDict:
    """
    STAR ReadsPerGene.out.tab format:
      first 4 rows are summary rows
      col1 = gene_id
      col2 = unstranded
      col3 = stranded forward
      col4 = stranded reverse
    """
    gene_counts = OrderedDict()

    with open(file_path, "r") as f:
        for i, line in enumerate(f):
            line = line.rstrip("\n")
            if not line:
                continue
            if i < 4:
                continue

            parts = line.split("\t")
            if len(parts) < count_col:
                continue

            gene_id = parts[0]
            value = parts[count_col - 1]

            try:
                gene_counts[gene_id] = float(value)
            except ValueError:
                gene_counts[gene_id] = 0.0

    return gene_counts


def main():
    args = parse_args()

    if not (len(args.inputs) == len(args.samples) == len(args.groups)):
        raise ValueError("--inputs, --samples, and --groups must have the same length")

    all_gene_ids = []
    seen = set()
    sample_dicts = {}

    for in_file, sample in zip(args.inputs, args.samples):
        counts = read_star_gene_counts(in_file, args.column)
        sample_dicts[sample] = counts
        for gene_id in counts.keys():
            if gene_id not in seen:
                seen.add(gene_id)
                all_gene_ids.append(gene_id)

    matrix = pd.DataFrame(index=all_gene_ids)

    for sample in args.samples:
        counts = sample_dicts[sample]
        matrix[sample] = [counts.get(gene_id, 0.0) for gene_id in all_gene_ids]

    matrix.to_csv(args.out_matrix, sep="\t")

    sample_info = pd.DataFrame({
        "sample": args.samples,
        "group": args.groups
    })
    sample_info.to_csv(args.out_sample_info, sep="\t", index=False)


if __name__ == "__main__":
    main()