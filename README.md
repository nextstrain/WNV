# Twenty years of West Nile Virus in North America

**This is the repository used to build [nextstrain.org/WNV/NA](https://nextstrain.org/WNV/NA)**

---

**Please note, this build uses a modular version of the [nextstrain pipeline](https://github.com/nextstrain/augur) (i.e. augur) which is currently in flux. This message will be removed once a stable version is released.**


This repository contains the build steps which:
* combine the curated FASTA file with metadata from a CSV and ENTREZ
* align the genomes
* infer a ML tree & internal node dates
* infer ancestral state of various traits via a DTA model
* export auspice-compatable JSONs ([Auspice](https://github.com/nextstrain/auspice) is the visualisation component of [nextstrain](https://nextstrain.org))



### Install instructions
_P.S. these installation instructions will become much simpler in the coming weeks as we roll out modular augur_

1. Clone the appropriate repositories as sister directories.
```bash
cd nextstrain # name the folder as you please
git clone git@github.com:nextstrain/WNV.git # this repo
git clone git@github.com:nextstrain/augur.git # the nextstrain bioinformatics toolkit
git clone git@github.com:nextstrain/auspice.git # the nextstrain visualisation component
mkdir WNV/data auspice/data
```

2. install conda (optional, but highly recommended)

I highly recommend using [conda](https://conda.io/docs/user-guide/install/index.html) which manages virtual environments for the python packages etc used by the nextstrain tools.
This allows you to ensure that no system-wide packages are affected, and if anything goes wrong to start again from scratch.
Check that conda has been installed and is available by running `conda --version`.
Create a new conda environment (which i've named `nextstrain`) via `conda create -n nextstrain python=3.6`, and activate it via `source activate nextstrain`.
You should see "(nextstrain)" appear at your terminal prompt.
Note that each time you want to run any of these tools you'll have to ensure that this environment is active.

3. Install required dependencies etc
```bash
conda install -c biocore mafft, iqtree, snakemake # aligner, phylogenetic inference, build tool
conda install -c conda-forge nodejs=9.11.1 # installs node & npm (javascript)
cd augur # augur is the nextstrain bioinformatics toolkit
pip install --process-dependency-links . # install the augur dependencies and augur as a python package
cd .. # return to the root (nextstrain) directory
cd auspice # auspice is the visualisation component of nextstrain
npm install # install the auspice dependencies
cd .. # return to the root (nextstrain) directory
```

Run `augur -h` to ensure that things have been installed.


### Run the build


#### Prerequisites:
The build expects a number of starting files in the `./data` directory.
These are not part of the git repository, so you have to move / create the two required files here: `WNV/data/zika.fasta` and `WNV/data/headers.csv` (these are referenced in `WNV/Snakefile`).

#### What will be produced:
* `./results/` will contain a number of files including the alignment, newick trees etc
* `./auspice/` will contain the two JSONs necessary for visualisation

#### Steps:
The builds use snakemake, which uses the instructions in `./WNV/Snakefile` to run the necessary steps of the pipeline.
Reading `./WNV/Snakefile` explains the steps ("align", "translate", "build_tree" etc), each of which is a seperate module of `augur` (which we installed above).
While snakemake will run all of these steps for you, one could equally run each one in the terminal.
(There's also some custom WNV scripts located in `./WNV/scripts` which the Snakefile references).
```bash
cd WNV
snakemake clean # remove any files from a previous build
snakemake # run the build pipeline. Takes about 10min
```


### Visualise the results
We're now going to start a local version of Auspice, the visualisation component behind nextstrain.org, to visualise our JSONs.
```bash
cd ../auspice
cp ../WNV/auspice/*json ./data/ # Auspice looks in the ./data folder to source JSONs
npm run start:local
```
And now you should be able to open a web browser to `localhost:4000/WNV/NA` to see the results :tada:


### Deploy the JSONs to nextstrain.org
_This won't be necessary once we start sourcing from the github repo. Not yet implemented._
