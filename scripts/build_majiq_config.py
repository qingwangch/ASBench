#!/usr/bin/env python3
import argparse

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sample", required=True)
    ap.add_argument("--group", required=True)
    ap.add_argument("--bam", required=True)
    ap.add_argument("--gtf", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    with open(args.out, "w") as f:
        f.write("[info]\n")
        f.write("readlen=150\n\n")
        f.write("[experiments]\n")
        f.write(f"{args.sample}={args.bam}\n")

if __name__ == "__main__":
    main()