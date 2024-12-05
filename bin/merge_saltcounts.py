#!/usr/bin/env python
import pandas as pd
import argparse
import sys
import os.path

def parse_args(args=None):
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--counts",
        required=True,
        metavar="FILE",
        help="Salt counts tables.",
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
    data = []
    # Iterate through all count files in subdirectories
    for file_path in args.counts:
        # Extract the sample ID from the folder name
        sample_id = os.path.basename(os.path.dirname(file_path))
        
        # Read the file
        df = pd.read_csv(file_path, sep='\t', header=None)
        
        # Assign column names (since there's no header)
        df.columns = ['bin_full', 'gene_length', 'gene_count', 'unknown_column']
        
        # Extract the bin ID, gene name, and additional info from the 'bin_full' column
        df['bin_id'] = df['bin_full'].str.extract(r'bin_(SPAdes-MetaBAT2-[^_]+_\d+\.\d+)')  # Adjusted to include the `.number`
        df['gene_name'] = df['bin_full'].str.extract(r'gene_([^_]+_\d+)')
        df['gene_info'] = df['bin_full'].str.extract(r'gene_[^_]+_\d+_(.+)')
        
        # Add the sample ID to the dataframe
        df['sample_id'] = sample_id
        
        # Select relevant columns
        df = df[['sample_id', 'bin_id', 'gene_name', 'gene_info', 'gene_length', 'gene_count', 'unknown_column']]
        
        # Append to the data list
        data.append(df)

    # Combine all dataframes into one
    merged_df = pd.concat(data, ignore_index=True)

    # Save the merged dataframe to a long TSV file
    merged_df.to_csv(args.out, sep='\t', index=False)
    
if __name__ == "__main__":
    sys.exit(main())