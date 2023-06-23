import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

# DO "grep Loop log.lammps. >& timings" FIRST

loop = []
cores = []

with open("timings","r") as f:
    for line in f:
        loop.append( line.split()[3] )
        cores.append( line.split()[5] )

loop = np.array( loop, dtype=float )
cores = np.array( cores, dtype=float )
#eff = loop[0]/cores/loop
#nodes = cores / 96
nodes = cores 
eff = loop[0]/nodes/loop

plt.plot(cores, eff, "o")
plt.savefig('core_scalability.png')

#df = pd.DataFrame({"cores" : cores, "loop": loop, "efficiency" : eff})
df = pd.DataFrame({"cores" : cores, "nodes": nodes, "loop": loop, "efficiency" : eff})
df = df.sort_values(by=["cores"])
df.to_csv("efficiency.csv", index=False)
