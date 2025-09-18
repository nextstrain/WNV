"""
This part of the workflow subsamples sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = results/metadata.tsv
    sequences   = results/equences.fasta

OUTPUTS:

    metadata_subsampled = results/metadata_filtered.tsv
    sequences_subsampled = results/sequences_filtered.fasta

This part of the workflow usually includes one or more of the following steps:

    - augur filter

See Augur's usage docs for these commands for more details.
"""

rule subsample:
    input:
        metadata = input_metadata,
        sequences = input_sequences,
    output:
        subsampled_strains = "results/{build}/subsampled_strains_{subsample}.txt",
    log:
        "logs/{build}/{subsample}/subsampled_strains.txt",
    benchmark:
        "benchmarks/{build}/{subsample}/subsampled_strains.txt",
    params:
        exclude = lambda w: conditional("--exclude", config["build_params"][w.build]["subsample"][w.subsample].get("exclude")),
        exclude_all = lambda w: conditional("--exclude-all", config["build_params"][w.build]["subsample"][w.subsample].get("exclude_all")),
        exclude_ambiguous_dates_by = lambda w: conditional("--exclude-ambiguous-dates-by", config["build_params"][w.build]["subsample"][w.subsample].get("exclude_ambiguous_dates_by")),
        exclude_where = lambda w: conditional("--exclude-where", config["build_params"][w.build]["subsample"][w.subsample].get("exclude_where")),
        group_by = lambda w: conditional("--group-by", config["build_params"][w.build]["subsample"][w.subsample].get("group_by")),
        group_by_weights = lambda w: conditional("--group-by-weights", config["build_params"][w.build]["subsample"][w.subsample].get("group_by_weights")),
        include = lambda w: conditional("--include", config["build_params"][w.build]["subsample"][w.subsample].get("include")),
        include_where = lambda w: conditional("--include-where", config["build_params"][w.build]["subsample"][w.subsample].get("include_where")),
        max_date = lambda w: conditional("--max-date", config["build_params"][w.build]["subsample"][w.subsample].get("max_date")),
        max_length = lambda w: conditional("--max-length", config["build_params"][w.build]["subsample"][w.subsample].get("max_length")),
        min_date = lambda w: conditional("--min-date", config["build_params"][w.build]["subsample"][w.subsample].get("min_date")),
        min_length = lambda w: conditional("--min-length", config["build_params"][w.build]["subsample"][w.subsample].get("min_length")),
        non_nucleotide = lambda w: conditional("--non-nucleotide", config["build_params"][w.build]["subsample"][w.subsample].get("non_nucleotide")),
        probabilistic_sampling = lambda w: conditional("--probabilistic-sampling", config["build_params"][w.build]["subsample"][w.subsample].get("probabilistic_sampling")),
        query = lambda w: conditional("--query", config["build_params"][w.build]["subsample"][w.subsample].get("query")),
        query_columns = lambda w: conditional("--query-columns", config["build_params"][w.build]["subsample"][w.subsample].get("query_columns")),
        # FIXME: --no-probabilistic-sampling?
        # FIXME: --priority?
        sequences_per_group = lambda w: conditional("--sequences-per-group", config["build_params"][w.build]["subsample"][w.subsample].get("sequences_per_group")),
        subsample_max_sequences = lambda w: conditional("--subsample-max-sequences", config["build_params"][w.build]["subsample"][w.subsample].get("subsample_max_sequences")),
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            {params.exclude_all:q} \
            {params.exclude_ambiguous_dates_by:q} \
            {params.exclude_where:q} \
            {params.exclude:q} \
            {params.group_by_weights:q} \
            {params.group_by:q} \
            {params.include_where:q} \
            {params.include:q} \
            {params.max_date:q} \
            {params.max_length:q} \
            {params.min_date:q} \
            {params.min_length:q} \
            {params.non_nucleotide:q} \
            {params.probabilistic_sampling:q} \
            {params.query_columns:q} \
            {params.query:q} \
            {params.sequences_per_group:q} \
            {params.subsample_max_sequences:q} \
            --output-strains {output.subsampled_strains} 2>&1 | tee {log}
        """

rule extract_subsampled_sequences_and_metadata:
    input:
        sequences = input_sequences,
        metadata = input_metadata,
        subsampled_strains = lambda w: expand("results/{build}/subsampled_strains_{subsample}.txt", build=w.build, subsample=list(config["build_params"][w.build]["subsample"].keys()))
    output:
        sequences = "results/{build}/sequences_filtered.fasta",
        metadata = "results/{build}/metadata_filtered.tsv",
    log:
        "logs/{build}/extract_subsampled_sequences_and_metadata.txt",
    benchmark:
        "benchmarks/{build}/extract_subsampled_sequences_and_metadata.txt",
    params:
        id_column = config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.id_column} \
            --exclude-all \
            --include {input.subsampled_strains} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} 2>&1 | tee {log}
        """
