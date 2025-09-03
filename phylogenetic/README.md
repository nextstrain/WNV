# Phylogenetic

This workflow uses WNV metadata and sequences to produce one [Nextstrain datasets][]
that can be visualized in Auspice.

## Workflow Usage

The workflow to execute all Nextstrain builds can be run from the top level directory:
```
nextstrain build phylogenetic
```

The workflow to execute the Washington focused build can also be run from the top level directory:
```
nextstrain build phylogenetic --configfile build-configs/washington-state/config.yaml
```

Alternatively, the workflow can also be run from within the phylogenetic directory:
```
cd phylogenetic
nextstrain build .
```

This produces the default outputs of the phylogenetic workflow:

- auspice_json(s) = auspice/*.json

## Data Requirements

The core phylogenetic workflow will use two files output from the Ingest workflow 'metadata_all.tsv' and 'sequences_all.fasta'
Any desired data formatting and curations should be done as part of the [ingest](../ingest/) workflow.

## Subsampling

The first step in the phylogenetic workflow is to subsample (or filter) the data. The subsampling criteria are specified in the 
phylogenetic/config/defaults.yaml file. The criteria are then executed in the Snakefile using wildcards and an input function. 
Documentation about subsampling can be found here [filtering and subsampling] (https://docs.nextstrain.org/en/latest/guides/bioinformatics/filtering-and-subsampling.html#subsampling-within-augur-filter)


## Defaults

The defaults directory contains all of the default configurations for the phylogenetic workflow.

[defaults/config.yaml](defaults/config.yaml) contains all of the default configuration parameters
used for the phylogenetic workflow. Use Snakemake's `--configfile`/`--config`
options to override these default values.

## Snakefile and rules

The rules directory contains separate Snakefiles (`*.smk`) as modules of the core phylogenetic workflow.
The modules of the workflow are in separate files to keep the main phylogenetic [Snakefile](Snakefile) succinct and organized.

The `workdir` is hardcoded to be the phylogenetic directory so all filepaths for
inputs/outputs should be relative to the phylogenetic directory.

Modules are all [included](https://snakemake.readthedocs.io/en/stable/snakefiles/modularization.html#includes)
in the main Snakefile in the order that they are expected to run.

## Build configs

The build-configs directory contains custom configs and rules that override and/or
extend the default workflow.

- [ci](build-configs/ci/) - CI build that runs with example data

[Nextstrain datasets]: https://docs.nextstrain.org/en/latest/reference/glossary.html#term-dataset
