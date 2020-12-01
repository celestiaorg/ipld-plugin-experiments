import sys

import pandas as pd
from matplotlib.pylab import show

latencies_df = pd.read_json(sys.argv[1])
latencies_df.plot.bar()
show()
