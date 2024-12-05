import pandas as pd

# Input file paths
depths_file = "/projects/0/prjs0784/salt/results_beast/depths/bins/bin_depths_summary.tsv"
taxonomy_file = "/projects/0/prjs0784/salt/results_beast/Taxonomy/KRAKEN/KRAKEN/merged/bin_depths_summary_combined.tsv"
output_file = "/projects/0/prjs0784/salt/results_beast/bins_taxdepths.tsv"

# Load the data into a DataFrame without headers and set custom column names
df = pd.read_csv(depths_file, sep='\t', header=0)
df = df.rename(columns={"bin": "Bin"})
# print(df.columns)  # Check if the headers are read correctly

# Strip the .fa.gz suffix from the 'Bin' column
df["Bin"] = df["Bin"].str.replace(".fa.gz", "", regex=False)

# Convert to long format
df_long = df.melt(id_vars=["Bin"], var_name="Sample", value_name="Depth")

# Load taxonomy table
taxonomy_df = pd.read_csv(taxonomy_file, sep='\t')

print(df_long['Sample'].unique())  # Check unique values in the sample column
print(taxonomy_df['Sample'].unique())  # Check unique values in the sample column of tax_df
print(df_long['Bin'].unique())  # Check unique values in the bin column
print(taxonomy_df['Bin'].unique())  # Check unique values in the bin column of tax_df

# Merge the tables on 'Sample' and 'Bin'
merged_df = pd.merge(df_long, taxonomy_df, on=["Sample", "Bin"], how="inner")

# Save the merged table to a new file
merged_df.to_csv(output_file, sep='\t', index=False)

print(f"Merged table saved to {output_file}")
