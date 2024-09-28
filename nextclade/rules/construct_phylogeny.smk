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
    message: "Building tree"
    input:
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    log:
        "logs/tree.txt",
    benchmark:
        "benchmarks/tree.txt"
    params:
        threads = workflow.cores
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads {threads} 2>&1 | tee {log}
        """

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
          - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
        """
    input:
        tree = "results/tree_raw.nwk",
        alignment = "results/aligned.fasta",
        metadata = "data/metadata_all.tsv"
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    log:
        "logs/refine.txt",
    benchmark:
        "benchmarks/refine.txt"
    params:
        coalescent = "opt",
        date_inference = "marginal",
        clock_filter_iqd = 4,
        root = "AF481864" # pre-NY99
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --metadata-id-columns "accession" \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --root {params.root} 2>&1 | tee {log}
        """
