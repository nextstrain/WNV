"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
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
        metadata = "data/metadata_all.tsv"
    output:
        colors = "results/colors.tsv"
    shell:
        """
        python ../phylogenetic/scripts/make_colors.py {input.metadata} {output.colors}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        sequences = "data/sequences_all.fasta",
        reference = files.reference
    output:
        alignment = "results/aligned.fasta"
    params:
        threads = workflow.cores
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --fill-gaps \
            --reference-sequence {input.reference} \
            --nthreads {threads}
        """
