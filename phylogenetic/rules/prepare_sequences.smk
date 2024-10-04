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


rule download:
    """Downloading sequences and metadata from data.nextstrain.org"""
    output:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    params:
        sequences_url = config["sequences_url"],
        metadata_url = config["metadata_url"],
    shell:
        """
        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """

rule decompress:
    """Decompressing sequences and metadata"""
    input:
        sequences = "data/sequences.fasta.zst",
        metadata = "data/metadata.tsv.zst"
    output:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    shell:
        """
        zstd -d -c {input.sequences} > {output.sequences}
        zstd -d -c {input.metadata} > {output.metadata}
        """


rule create_colors:
    input:
        metadata = "results/metadata_filtered.tsv"
    output:
        colors = "results/colors.tsv"
    log:
            "logs/colors.txt",
    benchmark:
            "benchmarks/colors.txt"
    shell:
        """
        python ./scripts/make_colors.py {input.metadata} {output.colors} 2>&1 | tee {log}
        """

rule create_lat_longs:
    input:
        metadata = "results/metadata_filtered.tsv"
    output:
        lat_longs = "results/lat_longs.tsv"
    log:
        "logs/lat_longs.txt",
    benchmark:
        "benchmarks/lat_longs.txt"
    shell:
        """
        python ./scripts/create_lat_longs.py {input.metadata} {output.lat_longs} 2>&1 | tee {log}
        """

rule align:
    input:
        sequences = "results/sequences_filtered.fasta",
        reference = config["reference"]
    output:
        alignment = "results/aligned.fasta"
    log:
        "logs/align.txt",
    benchmark:
        "benchmarks/align.txt"
    params:
        threads = workflow.cores
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --output {output.alignment} \
            --fill-gaps \
            --reference-sequence {input.reference} \
            --nthreads {threads} 2>&1 | tee {log}
        """
