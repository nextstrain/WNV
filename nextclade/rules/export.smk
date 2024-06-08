"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

REQUIRED INPUTS:

    metadata        = data/metadata.tsv
    tree            = results/tree.nwk
    branch_lengths  = results/branch_lengths.json
    node_data       = results/*.json

OUTPUTS:

    auspice_json = auspice/${build_name}.json

    There are optional sidecar JSON files that can be exported as part of the dataset.
    See Nextstrain's data format docs for more details on sidecar files:
    https://docs.nextstrain.org/page/reference/data-formats.html

This part of the workflow usually includes the following steps:

    - augur export v2
    - augur frequencies

See Augur's usage docs for these commands for more details.
"""


rule export_v2:
    message: "Exporting data files for for auspice using V2 JSON schema"
    input:
        tree = "results/tree.nwk",
        metadata = "data/metadata_all.tsv",
        branch_lengths = "results/branch_lengths.json",
        traits = "results/traits.json",
        nt_muts = "results/nt_muts.json",
        aa_muts = "results/aa_muts.json",
        colors = "results/colors.tsv",
        auspice_config = "config/auspice_config_v2.json"
    output:
        auspice = "auspice/WNV-nextstrain_NA.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns "accession" \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --auspice-config {input.auspice_config} \
            --output {output.auspice}
        """
