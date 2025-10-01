"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata   = results/metadata.tsv
    sequences  = results/sequences.fasta

OUTPUTS:

    metadata   = results/{build}/metadata_filtered.tsv
    sequences  = results/{build}/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur subsample

See Augur's usage docs for these commands for more details.
"""

rule subsample:
    input:
        sequences = "results/sequences.fasta",
        metadata = "results/metadata.tsv",
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
        config_section = lambda w: ["build_params", w.build, "subsample"]
    threads: workflow.cores
    shell:
        """
        augur subsample \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            --config {input.config} \
            --config-section {params.config_section:q} \
            --nthreads {threads} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} 2>&1 | tee {log}
        """
