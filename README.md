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
The build can be run at once or by workflows. Running the build by workflows can be helpful when troubleshooting or when testing modifications.
To run the build by workflows first run the ingest workflow
```bash
nextstrain build ingest
```
Inside the ingest folder there should be two output files: metadata_all.tsv and sequences_all.tsv

Run the phylogenetic workflow
```bash
nextstrain build phylogenetic
```
Inside the phylogenetic folder there should be at least one output file: WNV-nextstrain_NA.json

Run the build all at once
```bash
nextstrain build
```
## File Structure
This Nextstrain build follows the structure detailed in the [Pathogen Repo Guide](https://github.com/nextstrain/pathogen-repo-guide)

## Decision Points
The following are critical decisions that were made during the development of the WNV build that should be kept in mind when analyzing the data.

### Root Selection
The Global and the Washington focused WNV builds use different roots.

The Global WNV build uses the sequence [AF260968](https://www.ncbi.nlm.nih.gov/nuccore/AF260968.1) which is the first WNV L1 (cluster 1) strain recovered in Egypt from 1951.
_Mencattelli, G., Ndione, M.H.D., Silverj, A. et al. Spatial and temporal dynamics of West Nile virus between Africa and Europe. Nat Commun 14, 6440 (2023). https://doi.org/10.1038/s41467-023-42185-7_

The Washington focused WNV build uses the sequence [AF481864](https://www.ncbi.nlm.nih.gov/nuccore/AF481864) as this is the sequence that is most closely related to the sequences isolated from New York in 1999. 
_Hadfield J, Brito AF, Swetnam DM, Vogels CBF, Tokarz RE, Andersen KG, Smith RC, Bedford T, Grubaugh ND. Twenty years of West Nile virus spread and evolution in the Americas visualized by Nextstrain. PLoS Pathog. 2019 Oct 31;15(10):e1008042. doi: 10.1371/journal.ppat.1008042. PMID: 31671157; PMCID: PMC6822705._




