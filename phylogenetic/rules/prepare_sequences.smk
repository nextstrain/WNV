"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    sequences   = results/{build}/sequences_filtered.fasta
    reference   = (from config)

OUTPUTS:

    alignment = results/{build}/aligned.fasta

This part of the workflow usually includes the following steps:

    - augur index
    - augur filter
    - augur align
    - augur mask

See Augur's usage docs for these commands for more details.
"""

rule align:
    input:
        sequences = "results/{build}/sequences_filtered.fasta",
        reference = lambda w: config["build_params"][w.build]["reference"]
    output:
        alignment = "results/{build}/aligned.fasta"
    log:
        "logs/{build}/align.txt",
    benchmark:
        "benchmarks/{build}/align.txt"
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
