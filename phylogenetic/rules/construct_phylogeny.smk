"""
This part of the workflow constructs the phylogenetic tree.

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta

OUTPUTS:

    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json

This part of the workflow usually includes the following steps:

    - augur tree
    - augur refine

See Augur's usage docs for these commands for more details.
"""


rule tree:
    input:
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    log:
        "logs/tree.txt",
    benchmark:
        "benchmarks/tree.txt"
    threads: workflow.cores
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads {threads:q} 2>&1 | tee {log}
        """

rule refine:
    input:
        tree = "results/tree_raw.nwk",
        alignment = "results/aligned.fasta",
        metadata = "results/metadata_filtered.tsv",
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json",
    log:
        "logs/refine.txt",
    benchmark:
        "benchmarks/refine.txt"
    params:
        metadata_id_columns = config["strain_id_field"],
        root = config["root"],
        treetime_params = config["refine"]["treetime_params"],
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.metadata_id_columns} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --root {params.root} \
            --timetree \
            {params.treetime_params} \
            2>&1 | tee {log}
        """
