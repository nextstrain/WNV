"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

However, this configurable subsampling allows for tierred subsampling based on values placed in the config file.

REQUIRED INPUTS:

    metadata    = results/metadata.tsv
    sequences   = results/equences.fasta

OUTPUTS:

    metadata_subsampled = results/metadata_filtered.tsv
    sequences_subsampled = results/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur subsample

See Augur's usage docs for these commands for more details.
"""

ruleorder: subsample > filter_manual

rule subsample:
    input:
        sequences = input_sequences,
        metadata = input_metadata,
        config = "results/run_config.yaml",
    output:
        sequences = "results/{build}/sequences_filtered.fasta",
        metadata = "results/{build}/metadata_filtered.tsv",
    log:
        "logs/{build}/subsample.txt",
    benchmark:
        "benchmarks/{build}/subsample.txt",
    params:
        id_column = config["strain_id_field"],
        config_root = "subsample",
    shell:
        """
        augur subsample \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            --config {input.config} \
            --config-root {params.config_root} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} 2>&1 | tee {log}
        """
