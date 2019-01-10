from __future__ import print_function, division
import numpy as np
import matplotlib as mpl
from collections import defaultdict
mpl.use('TkAgg')
import matplotlib.pyplot as plt
import sys

# This script attempts to construct a colour palette for the states, locations etc used by WNV nextstrain.
# It is called by Snakemake, just before the final step (export)
# ARG1: METADATA ARG2: OUTPUT

with open(sys.argv[1], 'r') as f:
  raw = f.read().splitlines() 
  header = raw[0].split("\t")
  metadata = []
  for line in raw[1:]:
    metadata.append({header[i]:data for i, data in enumerate(line.split("\t"))})

fh = open(sys.argv[2], "w")

#########################################################################################
# COUNTRIES
countries    = ["USA",      "Mexico"]
country_cols = ["#511ea8",  "#dc2f24"]
fh.write("## COUNTRIES ##\n")
for pair in zip(countries, country_cols):
  fh.write("{}\t{}\t{}\n".format("country", pair[0], pair[1]))

#########################################################################################
# LINEAGES / STRAINS / CLADES (they're not monophyletic)
wnv_strain       = ["NY99",    "SW03",    "WN02"]
wnv_strain_cols  = ["#CBB742", "#7EB876", "#4988C5"]
fh.write("## WNV STRAINS / LINEAGES ##\n")
for pair in zip(wnv_strain, wnv_strain_cols):
  fh.write("{}\t{}\t{}\n".format("lineage", pair[0], pair[1]))

#########################################################################################
# STATES
# we (roughly) use time zones to form different colour scales for better resolution
states = {
  "other": ["HI", "AK"],
  "pacific": ["CA", "NV", "OR", "WA"],
  "mountain": ["AZ", "CO", "ID", "MT", "NM", "ND", "UT", "WY"],
  "central": ["AL", "AR", "IL", "IA", "KY", "LA", "KA", "MN", "MS", "MO", "NE", "ND", "OK", "SD", "TN", "TX", "WI"],
  "eastern": ["CE", "DE", "FL", "GA", "IN", "ME", "MD", "MA", "MI", "NH", "NJ", "NY", "NC", "OH", "PA", "RI", "SC", "VT", "VA", "DC", "WV"],
  "mexico": ["Chihuahua", "Sopnora", "Tamaulipas", "BajaCalifornia"]
}
# prune out the states that _aren't_ in the metadata (before we create the colour scale)
states_present = set([x["state"] for x in metadata])
for key, values in states.items():
  states[key] = list(filter(lambda x: x in states_present, values))
  # generate color maps
states_cols = {
  "other":     ["#bdbdbd", "#636363"],
  "pacific":   [mpl.colors.rgb2hex(mpl.cm.YlOrRd(i)) for i in np.linspace(0.3,1,len(states["pacific"]))],
  "mountain":  [mpl.colors.rgb2hex(mpl.cm.YlGn(i)) for i in np.linspace(0.3,1,len(states["mountain"]))],
  "central":   [mpl.colors.rgb2hex(mpl.cm.GnBu(i)) for i in np.linspace(0.3,1,len(states["central"]))],
  "eastern":   [mpl.colors.rgb2hex(mpl.cm.BuPu(i)) for i in np.linspace(0.3,1,len(states["eastern"]))],
  "mexico":    [mpl.colors.rgb2hex(mpl.cm.bone(i)) for i in np.linspace(0,0.7,len(states["mexico"]))]
}
fh.write("## STATES ##\n")
for category, names in states.items():
  for pair in zip(names, states_cols[category]):
    fh.write("{}\t{}\t{}\n".format("state", pair[0], pair[1]))

#########################################################################################
# HOSTS
# use the tab20c scale - https://matplotlib.org/examples/color/colormaps_reference.html
tab20     = [mpl.colors.rgb2hex(mpl.cm.tab20c(i)) for i in range(0,20)]
host      = ["Bird-crow", "Bird-other", "Human",  "Mosquito-Aedes", "Mosquito-Culex", "Mosquito-Culiseta", "Mosquito-other", "Horse",   "Squirrel", "Unknown", "Bird-unknown", "Mosquito-unknown" ]
host_cols = [tab20[0],     tab20[1],    tab20[4],  tab20[8],        tab20[9],         tab20[10],           tab20[11],        tab20[12], tab20[13],  "#DDDDDD",  tab20[2],      tab20[11]         ]
fh.write("## HOSTS ##\n")
for pair in zip(host, host_cols):
  fh.write("{}\t{}\t{}\n".format("host", pair[0], pair[1]))

#########################################################################################
# DIVISIONS
divisions = set(x["division"] for x in metadata)
divisions.discard("Unknown")
divisions.discard("division")
divisions = list(divisions)
divisions.sort(key=str.lower)
divisions_cols = [mpl.colors.rgb2hex(mpl.cm.viridis(i)) for i in np.linspace(0,1,len(divisions))]
fh.write("## DIVISIONS ##\n")
for pair in zip(divisions, divisions_cols):
  fh.write("{}\t{}\t{}\n".format("division", pair[0], pair[1]))

#########################################################################################
# END
fh.close()