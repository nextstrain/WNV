"""
This part of the workflow creates additonal annotations for the phylogenetic tree.

REQUIRED INPUTS:

    metadata            = data/metadata.tsv
    prepared_sequences  = results/prepared_sequences.fasta
    tree                = results/tree.nwk

OUTPUTS:

    node_data = results/*.json

    There are no required outputs for this part of the workflow as it depends
    on which annotations are created. All outputs are expected to be node data
    JSON files that can be fed into `augur export`.

    See Nextstrain's data format docs for more details on node data JSONs:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur traits
    - augur ancestral
    - augur translate
    - augur clades

See Augur's usage docs for these commands for more details.

Custom node data files can also be produced by build-specific scripts in addition
to the ones produced by Augur commands.
"""


rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        #tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        #alignment = rules.align.output
        alignment = "results/aligned.fasta"
    output:
        node_data = "results/nt_muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        #tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        #node_data = rules.ancestral.output.node_data,
        node_data = "results/nt_muts.json",
        reference = config["reference"]
    output:
        node_data = "results/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data} \
        """

rule traits:
    message: "Inferring ancestral traits for {params.metadata_columns!s}"
    input:
        tree = "results/tree.nwk",
        metadata = "results/metadata_filtered.tsv"
    output:
        node_data = "results/traits.json",
    params:
        metadata_id_columns = config["strain_id_field"],
        metadata_columns = config["traits"]["metadata_columns"],
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.metadata_columns} \
            --output {output.node_data} \
            --columns {params.metadata_columns} \
            --confidence
        """
