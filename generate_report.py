import sys
import os

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.backends.backend_pdf

# preserve the order of the list, but make each member unique by adding an index
def parse_default_regions(regions):
    out = []
    counts = {}
    for region in regions:
        if region in counts:
            counts[region] = counts[region] + 1
        else:
            counts[region] = 1
        out.append("{}-{}".format(region, counts[region]))
    return out

# todo(evan): don't hard-code regions
# use the default regions found in ./terraform/cluster/variables.tf
default_regions = [ "LON1", "AMS3", "FRA1", "NYC3", "BLR1", "SFO2", "NYC3", "SFO2", "SGP1", "TOR1", "AMS3", "FRA1", "LON1", "NYC3", "SFO2", "SGP1", "TOR1", "AMS3", "FRA1", "LON1", "NYC3", "SFO2", "SGP1", "TOR1"]

# make each instance of a region unique by adding an index
regions = parse_default_regions(default_regions)


file_pattern = "{}/dag-experiments-node-{}/{}_latencies.json"

# use the first provided arg as the path
path = sys.argv[1]

# assume that each node has its own directory
num_nodes = 0
for _, dirs, _ in os.walk(path):
    for d in dirs:
        num_nodes += 1

################################
#   Utilities
################################

# divide each data set by one million
def scale_to_ms(df, col):
    df[col] = df[col] / 1000000
    return df

def scale_df_to_ms(df):
    for col in df:
        df = scale_to_ms(df, col)
    return df

# combine each column of a df into a single column
# (you'll probs wanna use df.copy())
def flatten_df(df):
    return df.stack().reset_index()

# opens the files into the base data processing dataframes
def open_files():
    samples = pd.DataFrame()
    da_proofs = pd.DataFrame()
    for i in range(num_nodes):
        # add each regoin's sample data
        samples[regions[i]] = pd.read_json(file_pattern.format(path, i, "sample"))[0]
        # add each region's proof data
        da_proofs[regions[i]] = pd.read_json(file_pattern.format(path, i, "da_proof"))[0]

    return samples, da_proofs

def save_figures():
    pdf = matplotlib.backends.backend_pdf.PdfPages(path + "plots.pdf")
    for fig in range(1, plt.gcf().number + 1):  ## will open an empty extra figure :(
        pdf.savefig(fig)
    pdf.close()

################################
#   Plotting
################################

def plot_average_da_proof(df):
    # consolidate data into a single series
    consolidated = flatten_df(df.copy())
    global_mean, global_std = consolidated.mean(), consolidated.std()

    # process data
    processed_df = pd.DataFrame(
        [
            {
                "mean": row.mean(), 
                "std": row.std(),
            } 
            for _, row in df.iterrows()
        ]
    )

    # plot errorbars
    plt.errorbar(
        x= [x for x in processed_df.index],
        y=processed_df["mean"],
        yerr=processed_df["std"],
        fmt= "o",
    )
    
    # plot horizontal global lines
    plt.axhline(y=global_mean[0], linestyle=(0, (5,1)), color="green", label="Global Average")
    plt.axhline(y=global_mean[0]-global_std[0], linestyle=(0, (5,1)), color="orange", label="Global StdDev")
    plt.axhline(y=global_mean[0]+global_std[0], linestyle=(0, (5,1)), color="orange")

    # format plot
    plt.legend(loc="best")
    plt.title("Average Latency per DA Proof Across All Nodes")
    plt.xlabel("DA Proof")
    plt.ylabel("Latency (ms)")
    plt.figure()
    return global_mean, global_std

# group the sampling df into 15 sized samples
# pass in a column of the samples_df provided by open_files
def plot_region_da_proof(df, region, global_mean, global_std, num_proofs):
    # get the average for the entire region
    region_mean = df.mean()

    # manually process instead of using groupby
    processed_df = pd.DataFrame(
        [
            {
                "mean": batch.mean(),
                "std": batch.max() - batch.min(),
            } 
            for batch in np.split(df, num_proofs)
        ],
    )
    
    # plot horizontal global lines
    plt.axhline(y=region_mean, linestyle="-", color="fuchsia", label="Region Average")
    plt.axhline(y=global_mean, linestyle=(0, (5,1)), color="green", label="Global Average")
    plt.axhline(y=global_mean-global_std, linestyle=(0, (5,1)), color="orange", label="Global StdDev")
    plt.axhline(y=global_mean+global_std, linestyle=(0, (5,1)), color="orange")

    # plot errorbars
    plt.errorbar(
        x= [x for x in processed_df.index],
        y=processed_df["mean"],
        yerr=processed_df["std"],
        fmt= "o",
    )
    
    # format plot
    plt.legend(loc="best")
    plt.title("Average Latency per DA Proof for {}".format(region))
    plt.xlabel("DA Proof")
    plt.ylabel("Latency (ms)")
    plt.figure()

def plot_latency_hist(df, plot_type, bin_size):
    combined = flatten_df(df)

    # calculate the number of bins needed
    min, max = combined[0].min(), combined[0].max()
    num_bins = (max - min) / bin_size

    # formatting
    plt.title("{} Latency Distribution for All Nodes".format(plot_type))
    plt.ylabel("Number of Requests")
    plt.xlabel("Latency (ms ({}/bar))".format(bin_size))
    plt.hist(combined[0], bins=int(num_bins))
    plt.figure()


def plot_region_comparisons(df, plot_type, w=.15):
    # process the input data
    processed_df = pd.DataFrame(
        [
            {
            "min": df[region].min(),
            "max": df[region].max(), 
            "mean": df[region].mean(), 
            "median": df[region].median(),
            }
            for region in df
        ], 
        index=[region for region in df]
        )
    ind = np.arange(len(processed_df.index))
    
    # add bars to plot
    for i, col in enumerate(processed_df):
        extra_width = w * i
        plt.bar(ind + extra_width, processed_df[col], w, label=col)

    # format plot
    plt.xticks(ind + ((3/2) *w), [row for row in processed_df.index], fontsize=8)
    plt.legend(loc="best")
    plt.title("Region {} Latency Statistics".format(plot_type))
    plt.xlabel("Regions")
    plt.ylabel("Latency (ms)")
    plt.figure()
    return

################################
#   Main
################################

# todo(evan): 
#   - combine data from nodes in the same regions


def main():
    # open the files
    samples, da_proofs = open_files()
    samples, da_proofs = scale_df_to_ms(samples), scale_df_to_ms(da_proofs)

    # plot the latency distribution in ~200 ms windows
    plot_latency_hist(samples.copy(), "Sampling", 200)

    # plot the comparisons between each region's sampling latency
    plot_region_comparisons(samples.copy(), "Sampling")
    
    # plot the global average for DA proofs
    global_mean, global_std = plot_average_da_proof(da_proofs)

    # Plot da proof latencies for each region
    for region in samples:
        plot_region_da_proof(samples[region], region, global_mean[0], global_std[0], 25)
    
    # plt.show()
    save_figures()

if __name__ == "__main__":
    main()
