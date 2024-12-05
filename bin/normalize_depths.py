#!/usr/bin/env python
import pandas as pd
import argparse
import sys

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
    try:
        # Load the depths file
        print(f"Loading file: {args.depths}")
        df = pd.read_csv(args.depths, sep="\t")

        if df.empty:
            print(f"Warning: The file {args.depths} is empty. Skipping normalization.")
            return

        print("File loaded successfully.")
        print(f"Columns in the file: {df.columns}")

        # Ensure the first column is 'Bin' and the rest are numeric columns to normalize
        if len(df.columns) < 2:
            raise ValueError("The input file must have at least two columns: 'Bin' and depth values.")

        cols_to_normalize = df.columns[1:]
        if not all(pd.api.types.is_numeric_dtype(df[col]) for col in cols_to_normalize):
            raise ValueError("All columns except the first ('Bin') must be numeric for normalization.")

        # Normalize each depth column
        df[cols_to_normalize] = df[cols_to_normalize].div(df[cols_to_normalize].sum(axis=0), axis=1) * 100

        # Save the normalized file
        df.to_csv(args.out, sep="\t", index=False)
        print(f"Normalized depths written to {args.out}")

    except FileNotFoundError:
        print(f"Error: The file {args.depths} does not exist.")
    except pd.errors.EmptyDataError:
        print(f"Error: The file {args.depths} is empty or malformed.")
    except Exception as e:
        print(f"Error normalizing file {args.depths}: {e}")

if __name__ == "__main__":
    sys.exit(main())
