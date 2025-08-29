"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = results/metadata.tsv
    sequences   = results/equences.fasta

OUTPUTS:

    metadata_subsampled = results/metadata_filtered.tsv
    sequences_subsampled = results/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur filter

See Augur's usage docs for these commands for more details.
"""

rule subsample:
    input:
        metadata = input_metadata,
        sequences = input_sequences,
    output:
        subsampled_strains = "results/{build}/subsampled_strains_{subsample}.txt",
    log:
        "logs/{build}/{subsample}/subsampled_strains.txt",
    benchmark:
        "benchmarks/{build}/{subsample}/subsampled_strains.txt",
    params:
        filters = lambda w: config["subsampling"][w.subsample],
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            {params.filters} \
            --output-strains {output.subsampled_strains} 2>&1 | tee {log}
        """

rule extract_subsampled_sequences_and_metadata:
    input:
        sequences = input_sequences,
        metadata = input_metadata,
        subsampled_strains = expand("results/{build}/subsampled_strains_{subsample}.txt", build=builds, subsample=list(config["subsampling"].keys()))
    output:
        sequences = "results/{build}/sequences_filtered.fasta",
        metadata = "results/{build}/metadata_filtered.tsv",
    log:
        "logs/{build}/extract_subsampled_sequences_and_metadata.txt",
    benchmark:
        "benchmarks/{build}/extract_subsampled_sequences_and_metadata.txt",
    params:
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            --exclude-all \
            --include {input.subsampled_strains} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} 2>&1 | tee {log}
        """
