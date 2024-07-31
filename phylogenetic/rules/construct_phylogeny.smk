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
        #alignment = rules.align.output.alignment
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    params:
        threads = workflow.cores,
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --method raxml \
            --nthreads {threads}
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
        metadata = "results/metadata_filtered.tsv",
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json",
    params:
        metadata_id_columns = config["strain_id_field"],
        root = config["root"],
        date_inference = "marginal",
        coalescent = "opt",
        clock_filter_iqd = 4,
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
            --coalescent {params.coalescent} \
            --date-confidence \
            # --date-inference {params.date_inference} \
            # --clock-filter-iqd {params.clock_filter_iqd}
        """
