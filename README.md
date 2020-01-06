# Nextstrain build pipeline for the [WestNile 4K Project](https://westnile4k.org/)

**This is the repository used to build [nextstrain.org/WNV/NA](https://nextstrain.org/WNV/NA)**

---

This repository contains the steps to use [augur]() to build the WNV/NA dataset. 

## Installation / Set-Up

1. Install [conda](https://conda.io/docs/user-guide/install/index.html)

2. Install augur (and its dependencies) into a conda environment
```bash
git clone git@github.com:nextstrain/augur.git # the nextstrain bioinformatics toolkit
cd augur
conda env create -f environment.yml
export NCBI_EMAIL=<YOUR_EMAIL_HERE>
```
This creates the conda environment `augur` which we must be in for all remaining steps

3. Enable the conda environment
```bash
source activate augur
```

4. Install auspice
```bash
conda install -c conda-forge nodejs
npm install --global auspice
```

4. Clone this repository
```bash
git clone git@github.com:grubaughlab/WNV-nextstrain.git
cd WNV-nextstrain
```

6. Check augur & auspice are installed:
```bash
augur -h
auspice -h
```

## File Structure
* `Snakefile` - contains the augur / WNV-custom steps to run the build. Each snakemake command can be run as a bash command on it's own, but we use snakemake to simplify things.
* `./data/*` - the input files (private, and not committed to github). You are responsible for creating the two required files here: `./data/full_dataset.fasta` and `./data/headers.csv` (these are referenced in the `Snakefile`).
* `./scripts/*` custom WNV scripts. Called by commands in the `Snakefile.
* `./results/` augur will produce a number of (intermediate) files including the alignment, newick trees etc. Not committed to github.
* `./auspice/` will contain the JSONs necessary for visualisation by auspice.


## Run the build
The `Snakefile` details each step in the buil (See that file for the specifics).
As such, it should be as simple as running
```bash
snakemake clean # remove any files from a previous build
snakemake # run the build pipeline. Takes about 40min
```
and the entire build will run through.


It's worth explaining some of the commands here, many of which are quick and can be re-run on their own to change the output. (For instance, changing colours doesn't require you to re-run the tree building steps.)

The commands listed will re-run just those steps -- so it's best to have run through the entire `Snakefile` before tweaking steps. Note that you'll also have to run `snakemake --printshellcmds --force export` to regenerate the auspice JSONs for viewing.

#### Parsing the metadata CSV & adding authors:
```bash
snakemake clean #
snakemake --printshellcmds --force parse
snakemake --printshellcmds --force add_authors
snakemake export # will run all the remaining steps
```
Parses the input CSV + FASTA -- this involves parsing the dates, interpreting the header of the CSV etc etc.
The authors are added by a mixture of pattern matching strain names, as well as querying entrez for author information.
The latter step is slow, and so a cache is created at `./results/author_cache.tsv` so that repeating this step can run faster.
See `./scripts/add_authors.py` for more information.

#### Generating colours:
```bash
snakemake --printshellcmds --force create_colors
snakemake --printshellcmds --force export
```
This uses the `./scripts/make_colors.py` script to dynamically generate a colour palette. 
Please edit this file to make changes to the colour scheme.


#### Generating lat-longs:
```bash
snakemake --printshellcmds --force create_lat_longs
snakemake --printshellcmds --force export
```
This uses the `./scripts/create_lat_longs.py` script to dynamically generate the lat-longs based on the contents of the metadata file.
Currently _all_ the states are hardcoded here (only those present in the metadata are actually exported tho), and the divisions are created dynamically by averaging the GPS values provided for each sample. The latter approach may wish to be improved.



#### Visualise the results:
From within the current directory, simply run `auspice view --datasetDir ./auspice` and then load *http://localhost:4000/* in a browser to see the results :tada:


#### Deploy the JSONs to nextstrain.org
_Currently this has to be done from the Bedford Lab_
