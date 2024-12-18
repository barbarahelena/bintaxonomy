#!/usr/bin/env python
import pandas as pd
import argparse
import sys

def parse_args(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-d",
        "--depths",
        required=True,
        metavar="FILE",
        help="Bin depths summary file.",
    )
    parser.add_argument(
        "-t",
        "--tax",
        required=True,
        metavar="FILE",
        help="Bin depths summary file.",
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
    # Load the data into a DataFrame without headers and set custom column names
    df = pd.read_csv(args.depths, sep='\t', header=0)
    df = df.rename(columns={"bin": "Bin"})
    # print(df.columns)  # Check if the headers are read correctly

    # Strip the .fa.gz suffix from the 'Bin' column
    df["Bin"] = df["Bin"].str.replace(".fa.gz", "", regex=False)

    # Convert to long format
    df_long = df.melt(id_vars=["Bin"], var_name="Sample", value_name="Depth")

    # Load taxonomy table
    taxonomy_df = pd.read_csv(args.tax, sep='\t')

    # Merge the tables on 'Sample' and 'Bin'
    merged_df = pd.merge(df_long, taxonomy_df, on=["Sample", "Bin"], how="inner")

    # Save the merged table to a new file
    merged_df.to_csv(args.out, sep='\t', index=False)

    print(f"Merged table saved to {args.out}")

if __name__ == "__main__":
    sys.exit(main())
