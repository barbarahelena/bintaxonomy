#!/usr/bin/env python
import pandas as pd
import argparse
import sys
import os.path

def parse_args(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-td",
        "--taxdepth",
        required=True,
        metavar="FILE",
        help="Taxonomy and depths table.",
    )
    parser.add_argument(
        "-s",
        "--salt",
        required=True,
        metavar="FILE",
        help="Salt genes summary file.",
    )
    parser.add_argument(
        "-o",
        "--out",
        required=True,
        metavar="FILE",
        type=argparse.FileType("w"),
        help="Output file containing final summary.",
    )
    return parser.parse_args(args)

def main(args=None):
    args = parse_args(args)

    # Load the data into a DataFrame without headers and set custom column names
    df = pd.read_csv(args.salt, sep='\t', header=0)
    df = df.rename(columns={"bin_id": "Bin", "sample_id": "Sample"})
    # print(df.columns)  # Check if the headers are read correctly

    # Load taxonomy table
    taxonomy_df = pd.read_csv(args.taxdepth, sep='\t')

    # Merge the tables on 'Sample' and 'Bin'
    merged_df = pd.merge(df, taxonomy_df, on=["Sample", "Bin"], how="inner")

    # Save the merged table to a new file
    merged_df.to_csv(args.out, sep='\t', index=False)

    print(f"Merged table saved to {args.out}")
    
if __name__ == "__main__":
    sys.exit(main())
