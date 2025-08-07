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

rule align:
    input:
        sequences = f"results/{build}/sequences_filtered.fasta",
        reference = config["reference"]
    output:
        alignment = f"results/{build}/aligned.fasta"
    log:
        f"logs/{build}/align.txt",
    benchmark:
        f"benchmarks/{build}/align.txt"
    threads: workflow.cores
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --fill-gaps \
            --reference-sequence {input.reference} \
            --remove-reference \
            --nthreads {threads:q} 2>&1 | tee {log}
        """
