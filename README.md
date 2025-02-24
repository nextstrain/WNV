# About
---

This repository analyzes West Nile Viral (WNV) genomes using [Nextstrain](https://nextstrain.org/) to understand the circulation and transmission of WNV within the United States. This repository was developed based on the WNV repository used for the Twenty years of West Nile Virus in the Americas [Nextstrain Narrative](https://nextstrain.org/WNV/NA)

## Data

This build pulls WNV genomes that are publicly available from NCBI.

## Installation
Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools. 

Clone this repository
```bash
git clone https://github.com/nextstrain/WNV.git
cd WNV
```

Try running Augur and Auspice
```bash
augur -help
auspice -help
```

## Run the build
This build can process and output global or Washington state focused WNV information. The build can also be run by workflows which is helpful when troubleshoting or all at once.

To run the build by workflows first run the ingest workflow
```bash
nextstrain build ingest
```
Inside the ingest folder there should be two output files: metadata_all.tsv and sequences_all.tsv

Run the phylogenetic workflow
Execute the global build
```bash
nextstrain build phylogenetic
```
Or execute the Washington focused build 
```bash
nextstrain build phylogenetic --configfile build-configs/washington-state/config.yaml
```
Inside the phylogenetic folder there should be at least one output file: WNV-nextstrain_NA.json

Run the build all at once. This option defaults to the global build.
```bash
nextstrain build phylogenetic
```

## File Structure
This Nextstrain build follows the structure detailed in the [Pathogen Repo Guide](https://github.com/nextstrain/pathogen-repo-guide)

## Decision Points
The following are critical decisions that were made during the development of the WNV build that should be kept in mind when analyzing the data.

### Global and Washington Focused Outputs
This build can process and output global or Washington state focused WNV information. To accomplish this, a washington-state.yaml file was added to the build-configs which specifies Washington subsampling preferences. This file can be adopted and mofidied to accomodate other sampling references appropiate to other regions or states.

### Root Selection
The Global and the Washington focused WNV builds use different roots.

The Global WNV build uses the sequence [AF260968](https://www.ncbi.nlm.nih.gov/nuccore/AF260968.1) which is the first WNV L1 (cluster 1) strain recovered in Egypt from 1951.
_Mencattelli, G., Ndione, M.H.D., Silverj, A. et al. Spatial and temporal dynamics of West Nile virus between Africa and Europe. Nat Commun 14, 6440 (2023). https://doi.org/10.1038/s41467-023-42185-7_

The Washington focused WNV build uses the sequence [AF481864](https://www.ncbi.nlm.nih.gov/nuccore/AF481864) as this is the sequence that is most closely related to the sequences isolated from New York in 1999. 
_Hadfield J, Brito AF, Swetnam DM, Vogels CBF, Tokarz RE, Andersen KG, Smith RC, Bedford T, Grubaugh ND. Twenty years of West Nile virus spread and evolution in the Americas visualized by Nextstrain. PLoS Pathog. 2019 Oct 31;15(10):e1008042. doi: 10.1371/journal.ppat.1008042. PMID: 31671157; PMCID: PMC6822705._

### Subsampling
The Washington focused WNV build pulls all the WNV sequences available in NCBI and filters the data in the phylogenetic workflow based on criteria defined in the config.yml file that is located inside the build-configs/washington-state folder. The subsampling criteria focuses on geographic location selecting all sequences from Washington, neighboring states, and region but up to a maximum of 5,000 sequences; and up to 300 sequences selected randomly from the rest of the states. All sequences have to meet a minimum genome length that is also specified as part of the subsampling criteria. There is more information about how to subsample data in Nextstrain here [Filter and Subsampling](https://docs.nextstrain.org/en/latest/guides/bioinformatics/filtering-and-subsampling.html)

### Lineage Designation
For global lineage designations, we query [pathoplexus](https://pathoplexus.org/)

### Host mapping to Host Genus and Host Type
We further refined the information in the NCBI Host column by categorizing it into **Host_Genus** and **Host_Type**, creating broader groupings for more effective data analysis. For example, the **Host** _Homo sapiens_ is classified under **Host_Genus** as _Homo_ and **Host_Type** as Human. This broader categorization is particularly useful for visualizing the phylogenetic tree. Instead of distinguishing between individual mosquito species, you can use the broader categories like **Host_Genus** _Culex_ or the higher-level category **Host_Type** Mosquito to color the tips of the tree.

### Determination of Mininum Genome Length
The average genome length of WNV is 10,948 bp. Nextstrain's phylogenetic workflow defaults to excluding sequences with less than 90% genome coverage, as the alignment of short sequences can be unreliable. However, due to the limited number of WNV sequences available in NCBI, we evaluated minimum genome length thresholds of 90% (9,800 bp), 80% (8,700 bp), 75% (8,200 bp), and 70% (7,700 bp). For each threshold, we ran the Washington-focused build and compared: (1) the number of sequences included, (2) data gap locations in the alignment files using an alignment viewer, and (3) the topology and lineage assignments from the phylogenetic tree outputs to determine the optimal threshold. We concluded that a minimum genome length of 75% (8,200 bp) included a higher number of sequences while balancing alignment quality. Lastly, we validated this threshold using the global build.
* To modify the minimum length of nucleotide sequence in the WNV global build enter the desired threshold in the --min-length <MIN_LENGTH> paremeter that is listed in the [defaults/config.yaml](https://github.com/nextstrain/WNV/blob/main/phylogenetic/defaults/config.yaml) file
* To modify the minimum length of nucleotide sequence in the WNV Washington focused build enter the desired threshold in the --min-length <MIN_LENGTH> paremeter that is listed in the [washington-state/config.yaml](https://github.com/nextstrain/WNV/blob/main/phylogenetic/build-configs/washington-state/config.yaml) file

