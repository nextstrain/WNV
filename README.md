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
This Nextstrain build follows the structure detailed in the [Pathogen Repo Guide] (https://github.com/nextstrain/pathogen-repo-guide)




