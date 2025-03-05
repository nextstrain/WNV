# West Nile Virus (WNV) Global and Washington Focused Builds
---
## Build Overview
- **Default Build Name**: WNV Global
- **State Based Build Name**: WNV Washington Focused Build
- **Pathogen/Strain**: West Nile Virus
- **Scope**: Full genome
- **Purpose**: This repository analyzes West Nile Viral (WNV) genomes using [Nextstrain](https://nextstrain.org/) to understand the circulation and transmission of WNV globally (WNV Global build) and within Washington State (WNV Washington Focused Build). This repository was developed based on the WNV repository used for the Twenty years of West Nile Virus in the Americas [Nextstrain Narrative](https://nextstrain.org/WNV/NA)
- **Nextstrain Build/s Location/s**: [Insert the URL for the Nextstrain build on Nextstrain Groups] [Insert another URL for instances when more than one Nextstrain build exists]

## Table of Contents
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Run the Build](#run-the-build)
- [Repository File Structure Overview](#repository-file-structure-overview)
- [Expected Outputs](#expected-outputs)
- [Scientific Decisions](#scientific-decisions)
- [Customization for Local Adaptation](#customization-for-local-adaptation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Getting Started
Some high-level features and capabilities specific to this build include:

- **Lineage Designation:** We use [Pathoplexus](https://pathoplexus.org/) for clade calling based off of a Nextclade dataset in this [PR](https://github.com/nextstrain/nextclade_data/pull/197)
- **Subsampling:** The WNV Washington Focused Build uses a tiered subsampling strategy which allows for filtering NCBI data based on geographic location. The subsampling criteria in the WNV Washington Focused Build is set to select all sequences from Washington, neighboring states, and region, up to a maximum of 5,000 sequences. Additionally, up to 300 sequences are randomly selected from other states. These criteria can be modified as needed.
- **Mapping Specific Locations:** We have added the option to map specific locations using coordinates in the WNV Washington Focused Build. This feature is useful for jurisdictions that need to map the locations of mosquito traps, for example.

### Data Sources & Inputs

This build pulls WNV genomes that are publicly available from NCBI.

- **Sequence and Metadata Data**: [NCBI](https://docs.nextstrain.org/en/latest/install.html](https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/virus?SeqType_s=Nucleotide&CollectionDate_dr=1950-01-01T00:00:00Z%20TO%20NOW&CreateDate_dt=1950-01-01T00:00:00Z%20TO%20NOW&VirusLineage_ss=West%20Nile%20virus,%20taxid:11082))
- **Expected Inputs**:
    - `ingest/data/sequences.fasta` (containing WNV genome sequences)
    - `ingest/data/metadata.tsv` (with relevant sample information)
- **Private geolocation data, if applicable**:
    - `phylogenetic/defaults/wa/annotations.tsv` (containing location name, latitude, and longitude information)
    
### Setup & Dependencies
#### Installation
Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools. 

#### Clone the repository
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
This build can process and output global or Washington state focused WNV information. The build can also be run all at once or by workflows which is helpful when troubleshooting.

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

## Repository File Structure Overview
This Nextstrain build follows the structure detailed in the [Pathogen Repo Guide](https://github.com/nextstrain/pathogen-repo-guide).
Mainly, this build contains two workflows for the analysis of WNV data:
- [ingest/](https://github.com/nextstrain/WNV/tree/main/ingest) Download data from NCBI, clean, format, curate it, and assign clades.
- [phylogenetic/](https://github.com/nextstrain/WNV/tree/main/phylogenetic) Subsample data and make phylogenetic trees for use in nextstrain.

## Expected Outputs
After successfully running the build there will be two output folders containing the build results.

- `phylogenetic/auspice/` folder contains: a file called `WNV_genome.json`
- `results/` folder contains: multiple files which include the aligned sequences, subsampled sequences, and phylogenetic trees in .nwk format

## Scientific Decisions
The following are critical decisions that were made during the development of the WNV build that should be kept in mind when analyzing the data.

### Global and Washington Focused Outputs
This build can process and output global or Washington state focused WNV information. To accomplish this, a washington-state.yaml file was added to the build-configs which specifies Washington subsampling preferences. This file can be adopted and modified to accommodate other sampling references appropriate to other regions or states.

### Root Selection
The Global and the Washington focused WNV builds use different roots.

The Global WNV build uses the sequence [AF260968](https://www.ncbi.nlm.nih.gov/nuccore/AF260968.1) which is the first WNV L1 (cluster 1) strain recovered in Egypt from 1951.
_Mencattelli, G., Ndione, M.H.D., Silverj, A. et al. Spatial and temporal dynamics of West Nile virus between Africa and Europe. Nat Commun 14, 6440 (2023). https://doi.org/10.1038/s41467-023-42185-7_

The Washington focused WNV build uses the sequence [AF481864](https://www.ncbi.nlm.nih.gov/nuccore/AF481864) as this is the sequence that is most closely related to the sequences isolated from New York in 1999. 
_Hadfield J, Brito AF, Swetnam DM, Vogels CBF, Tokarz RE, Andersen KG, Smith RC, Bedford T, Grubaugh ND. Twenty years of West Nile virus spread and evolution in the Americas visualized by Nextstrain. PLoS Pathog. 2019 Oct 31;15(10):e1008042. doi: 10.1371/journal.ppat.1008042. PMID: 31671157; PMCID: PMC6822705._

### Lineage Designation
For global lineage designations, we query [pathoplexus](https://pathoplexus.org/)

### Host mapping to Host Genus and Host Type
We further refined the information in the NCBI Host column by categorizing it into **Host_Genus** and **Host_Type**, creating broader groupings for more effective data analysis. For example, the **Host** _Homo sapiens_ is classified under **Host_Genus** as _Homo_ and **Host_Type** as Human. This broader categorization is particularly useful for visualizing the phylogenetic tree. Instead of distinguishing between individual mosquito species, you can use the broader categories like **Host_Genus** _Culex_ or the higher-level category **Host_Type** Mosquito to color the tips of the tree.

### Determination of Minimum Genome Length
The average genome length of WNV is 10,948 bp. Nextstrain's phylogenetic workflow defaults to excluding sequences with less than 90% genome coverage, as the alignment of short sequences can be unreliable. However, due to the limited number of WNV sequences available in NCBI, we evaluated minimum genome length thresholds of 90% (9,800 bp), 80% (8,700 bp), 75% (8,200 bp), and 70% (7,700 bp). For each threshold, we ran the Washington-focused build and compared: (1) the number of sequences included, (2) data gap locations in the alignment files using an alignment viewer, and (3) the topology and lineage assignments from the phylogenetic tree outputs to determine the optimal threshold. We concluded that a minimum genome length of 75% (8,200 bp) included a higher number of sequences while balancing alignment quality. Lastly, we validated this threshold using the global build.
* To modify the minimum length of nucleotide sequence in the WNV global build enter the desired threshold in the --min-length <MIN_LENGTH> parameter that is listed in the [defaults/config.yaml](https://github.com/nextstrain/WNV/blob/main/phylogenetic/defaults/config.yaml) file
* To modify the minimum length of nucleotide sequence in the WNV Washington focused build enter the desired threshold in the --min-length <MIN_LENGTH> parameter that is listed in the [washington-state/config.yaml](https://github.com/nextstrain/WNV/blob/main/phylogenetic/build-configs/washington-state/config.yaml) file.

## Customization for Local Adaptation
This build can be customized for use by other jurisdictions, including as states, cities, counties, or countries.

### Subsampling
The Washington focused WNV build retrieves all available WNV sequences from NCBI and filters the data within the phylogenetic workflow based on criteria defined in the config.yaml file, located in the [build-configs/washington-state](https://github.com/nextstrain/WNV/blob/main/phylogenetic/build-configs/washington-state/config.yaml) folder. For details on the current subsampling configuration and instructions on modifying the criteria, refer to the [phylogenetic/build-configs/washington-state README.md](https://github.com/nextstrain/WNV/blob/main/phylogenetic/build-configs/washington-state/README.md).

### Incorporating Additional Metadata
We have added the option to integrate additional metadata, which can include either public or sensitive information. This feature is especially useful for jurisdictions that need to annotate the phylogenetic trees or map visualizations in Auspice. For example, in the Washington focused WNV build, we mapped the centroids of zip codes where mosquito traps are located. This information is within the phylogenetic workflow in the metadata.tsv file, located in the [phylogenetic/data-private](https://github.com/nextstrain/WNV/tree/main/phylogenetic/data-private) folder. For more details on the current metadata configuration and instructions on modifying it, refer to the [phylogenetic/data-private README.md](https://github.com/nextstrain/WNV/tree/main/phylogenetic/data-private).

## Contributing
For any questions please submit them to our [Discussions](insert link here) page otherwise software issues and requests can be logged as a Git [Issue](insert link here).

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements

*[add acknowledgements to those who have contributed to this work]*
