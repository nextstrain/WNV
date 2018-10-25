# Twenty years of West Nile Virus in North America

**This is the repository used to build [nextstrain.org/WNV/NA](https://nextstrain.org/WNV/NA)**

---

This repository contains the build steps which:
* combine the curated FASTA file with metadata from a CSV and ENTREZ
* align the genomes
* infer a ML tree & internal node dates
* infer ancestral state of various traits via a DTA model
* export auspice-compatable JSONs ([Auspice](https://github.com/nextstrain/auspice) is the visualisation component of [nextstrain](https://nextstrain.org))



## Installation / Set-Up

1. Install [conda](https://conda.io/docs/user-guide/install/index.html)

2. Install augur (and its dependencies) into a conda environment
```bash
git clone git@github.com:nextstrain/augur.git # the nextstrain bioinformatics toolkit
cd augur
conda env create -f environment.yml
export NCBI_EMAIL=<YOUR_EMAIL_HERE>
```

3. Install auspice (the visualisation tool)
```bash
conda install node
npm install --global auspice
```

4. Clone this repository
```bash
git clone git@github.com:grubaughlab/WNV-nextstrain.git
```

5. Activate the augur conda environment
```bash
source activate augur
```

6. Check augur & auspice are installed:
```bash
augur -h
auspice -h
```


## Run the build


#### Input files (private):
The build expects a number of starting files in the `./data` directory.
These are not part of the git repository, so you have to move / create the two required files here: `./data/full_dataset.fasta` and `./data/headers.csv` (these are referenced in `./Snakefile`).

#### What will be produced:
* `./results/` will contain a number of files including the alignment, newick trees etc
* `./auspice/` will contain the two JSONs necessary for visualisation by auspice

#### Run the analysis pipeline:
The builds use snakemake, which uses the instructions in `./Snakefile` to run the necessary steps of the pipeline.
Reading `./Snakefile` explains the steps ("align", "translate", "build_tree" etc), each of which is a seperate module of `augur` (which we installed above).
While snakemake will run all of these steps for you, one could equally run each one in the terminal.
(There's also some custom WNV scripts located in `./scripts` which the Snakefile references).
```bash
snakemake clean # remove any files from a previous build
snakemake # run the build pipeline. Takes about 10min
```


#### Visualise the results:
From within the current directory, simply run `auspice --data ./auspice` and then load *http://localhost:4000/local* in a browser to see the results :tada:


#### Deploy the JSONs to nextstrain.org
_Currently this has to be done from the bedford lab_
