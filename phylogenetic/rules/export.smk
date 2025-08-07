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


rule export:
    input:
        tree = f"results/{build}/tree.nwk",
        metadata = f"results/{build}/metadata_filtered.tsv",
        branch_lengths = f"results/{build}/branch_lengths.json",
        traits = f"results/{build}/traits.json",
        nt_muts = f"results/{build}/nt_muts.json",
        aa_muts = f"results/{build}/aa_muts.json",
        description = config["export"]["description"],
        auspice_config = config["export"]["auspice_config"],
    output:
        auspice = f"auspice/WNV_{build}.json"
    log:
        f"logs/{build}/export.txt",
    benchmark:
        f"benchmarks/{build}/export.txt"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns "accession" \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --description {input.description} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence-inline \
            --output {output.auspice} 2>&1 | tee {log}
        """

rule tip_frequencies:
    """
    Estimating KDE frequencies for tips
    """
    input:
        tree = f"results/{build}/tree.nwk",
        metadata = f"results/{build}/metadata_filtered.tsv",
    output:
        tip_freq = f"auspice/WNV_{build}_tip-frequencies.json"
    params:
        strain_id = config["strain_id_field"],
        min_date = config["tip_frequencies"]["min_date"],
        max_date = config["tip_frequencies"]["max_date"],
        narrow_bandwidth = config["tip_frequencies"]["narrow_bandwidth"],
        proportion_wide = config["tip_frequencies"]["proportion_wide"]
    shell:
        r"""
        augur frequencies \
            --method kde \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --min-date {params.min_date} \
            --max-date {params.max_date} \
            --narrow-bandwidth {params.narrow_bandwidth} \
            --proportion-wide {params.proportion_wide} \
            --output {output.tip_freq}
        """