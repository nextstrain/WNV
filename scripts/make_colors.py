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
# different colour scales where used to colour states based on five main US geographic regions
states = {
  "west": ["AK", "WA", "ID", "MT", "OR", "NV", "WY", "CA", "UT", "CO", "HI"],
  "southwest": ["AZ", "NM", "OK", "TX"],
  "midwest": ["ND", "MN", "IL", "WI", "MI", "SD", "IA", "IN", "OH", "NE", "MO", "KS"],
  "southeast": ["KY", "WV", "VA", "AR", "TN", "NC", "SC", "LA", "MS", "AL", "GA", "FL"],
  "northeast": ["ME", "VT", "NH", "NY", "MA", "RI", "PA", "NJ", "CT", "MD", "DC", "DE"],
  "mexico": ["Chihuahua", "Sonora", "Tamaulipas", "BajaCalifornia"]
}
# prune out the states that _aren't_ in the metadata (before we create the colour scale)
# states_present = set([x["state"] for x in metadata])
# for key, values in states.items():
#   states[key] = list(filter(lambda x: x in states_present, values))
  # generate color maps
states_cols = {
  "west": ["#590000", "#690909", "#7A1515", "#8A2424", "#9B3636", "#AB4B4B", "#BC6363", "#CD7E7E", "#DD9C9C", "#EEBDBD", "#FFE1E1"],
  "southwest": ["#E79000", "#EFB034", "#F7D169", "#FFF29E"],
  "midwest": ["#001C00", "#033003", "#0B450B", "#155915", "#236E23", "#348334", "#499749", "#60AC60", "#7BC17B", "#9AD59A", "#BBEABB", "#E1FFE1"],
  "southeast": ["#001833", "#052445", "#0C3258", "#17416A", "#24527D", "#34658F", "#4678A2", "#5C8DB4", "#73A3C7", "#8EBAD9", "#ABD2EC", "#CCEBFF"],
  "northeast": ["#1C001C", "#2E0330", "#3F0B45", "#501559", "#60236E", "#713483", "#824997", "#9460AC", "#A77BC1", "#BD9AD5", "#D5BBEA", "#F0E1FF"],
  "mexico":    [mpl.colors.rgb2hex(mpl.cm.Greys(i)) for i in np.linspace(0,0.7,len(states["mexico"]))]
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