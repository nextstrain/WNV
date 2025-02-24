"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/all_metadata_added.tsv
    sequences   = data/sequences.fasta
    reference   = ../shared/reference.fasta

OUTPUTS:

    prepared_sequences = results/prepared_sequences.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - augur align
    - augur mask

See Augur's usage docs for these commands for more details.
"""

rule create_colors:
    message:
        "Creating custom color scale in {output.colors}"
    input:
        metadata = "data/all_metadata_added.tsv"
    output:
        colors = "results/colors.tsv"
    log:
        "logs/colors.txt",
    benchmark:
        "benchmarks/colors.txt"
    shell:
        """
        python ../phylogenetic/scripts/make_colors.py {input.metadata} {output.colors} 2>&1 | tee {log}
        """

rule align:
    message:
        """
        Aligning sequences to {params.root}
          - filling gaps with N
        """
    input:
        sequences = "data/sequences_all.fasta",
    output:
        alignment = "results/aligned.fasta"
    log:
        "logs/align.txt",
    benchmark:
        "benchmarks/align.txt"
    params:
        threads = workflow.cores,
        root = "AF481864" # pre-NY99
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --fill-gaps \
            --reference-name {params.root} \
            --nthreads {threads} 2>&1 | tee {log}
        """
