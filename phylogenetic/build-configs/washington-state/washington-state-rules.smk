"""
These are washington specific rules for the phylogenetic workflow.
"""

rule create_lat_longs:
    """
    This rule creates an averaged lat_longs.tsv file from the metadata_filtered.tsv file, but this requires a USA state annotation. This rule fails on global datasets.
    """
    input:
        metadata = "results/{build}/metadata_filtered.tsv"
    output:
        lat_longs = "results/{build}/lat_longs.tsv"
    log:
        "logs/{build}/lat_longs.txt",
    benchmark:
        "benchmarks/{build}/lat_longs.txt"
    shell:
        """
        python ./scripts/create_lat_longs.py {input.metadata} {output.lat_longs} 2>&1 | tee {log}
        """


rule create_colors:
    input:
        metadata = "results/{build}/metadata_filtered.tsv"
    output:
        colors = "results/{build}/colors.tsv"
    log:
            "logs/{build}/colors.txt",
    benchmark:
            "benchmarks/{build}/colors.txt"
    shell:
        """
        python ./scripts/make_colors.py {input.metadata} {output.colors} 2>&1 | tee {log}
        """


rule export_washington_build:
    """
    This part of the workflow collects the phylogenetic tree and annotations to
    export a Nextstrain dataset.
    This includes incorporating the lat_long.tsv annotation.
    """
    input:
        tree = "results/{build}/tree.nwk",
        metadata = "results/{build}/metadata_filtered.tsv",
        branch_lengths = "results/{build}/branch_lengths.json",
        traits = "results/{build}/traits.json",
        nt_muts = "results/{build}/nt_muts.json",
        aa_muts = "results/{build}/aa_muts.json",
        colors = "results/{build}/colors.tsv",
        description = lambda w: config["build_params"][w.build]["export"]["description"],
        lat_longs = "results/{build}/lat_longs.tsv",
        auspice_config = lambda w: config["build_params"][w.build]["export"]["auspice_config"],
    output:
        auspice = "auspice/WNV_{build}.json"
    log:
        "logs/{build}/export.txt",
    benchmark:
        "benchmarks/{build}/export.txt"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns "accession" \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --description {input.description} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence-inline \
            --output {output.auspice} 2>&1 | tee {log}
        """

# Add a Snakemake ruleorder directive here if you need to resolve ambiguous rules
# that have the same output as the copy_example_data rule.
ruleorder: export_washington_build > export