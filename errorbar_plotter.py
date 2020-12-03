import sys
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.backends.backend_pdf

dir = sys.argv[1]
group_num = int(sys.argv[2])
num_nodes = int(sys.argv[3])

file_pattern = "dag-experiments-node-{}/sample_latencies.json"

for iter in range(num_nodes):
    try:
        file = dir + file_pattern.format(iter)
        print(file)
        sample_latencies_df = pd.read_json(file)
        grouped = sample_latencies_df.groupby(sample_latencies_df.index // group_num)
        grouped = grouped[0]
        indices = grouped.groups.keys()
        mean = grouped.mean()
        plt.errorbar(x=indices, y=mean, yerr=grouped.max() - grouped.min(), fmt='o')
        plt.figure()
        # plt.show()
    except:
        print()
        print("Exception:", sys.exc_info()[0], "occurred on: ", file)
        print("Next file.")
        print()

pdf = matplotlib.backends.backend_pdf.PdfPages(dir + "plots.pdf")
for fig in range(1, plt.gcf().number + 1):  ## will open an empty extra figure :(
    pdf.savefig(fig)
pdf.close()
