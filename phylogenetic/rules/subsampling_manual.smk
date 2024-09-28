"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = data/metadata.tsv
    sequences   = data/sequences.fasta

OUTPUTS:

    metadata_subsampled = results/metadata_filtered.tsv
    sequences_subsampled = results/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur filter

See Augur's usage docs for these commands for more details.
"""

rule filter_manual:
    input:
        metadata = config["input_metadata"],
        sequences = config["input_sequences"],
    output:
        sequences = "results/sequences_filtered.fasta",
        metadata = "results/metadata_filtered.tsv"
    log:
        "logs/filter_manual.txt",
    benchmark:
        "benchmarks/filter_manual.txt",
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns "accession" \
            --min-length '9800' \
            --output {output.sequences} \
            --query "country == 'USA' & accession != 'NC_009942'"  \
            --output-metadata {output.metadata} 2>&1 | tee {log}
        """
