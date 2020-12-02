import sys

import pandas as pd
import matplotlib.pylab as plt
from matplotlib.pylab import show

group_num = int(sys.argv[2])
sample_latencies_df = pd.read_json(sys.argv[1])

grouped = sample_latencies_df.groupby(sample_latencies_df.index // group_num)
grouped = grouped[0]
indices = grouped.groups.keys()
mean = grouped.mean()

plt.errorbar(x=indices, y=mean, yerr=grouped.max() - grouped.min(), fmt='o')

show()
