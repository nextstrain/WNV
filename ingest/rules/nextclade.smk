"""
This part of the workflow handles running Nextclade on the curated metadata
and sequences.
REQUIRED INPUTS:
    metadata    = data/raw_metadata_all.tsv
    sequences   = data/sequences_all.fasta
    nextclade_datasets = ../nextclade/dataset
OUTPUTS:
    metadata        = data/metadata_all.tsv
    nextclade       = data/nextclade_clades.tsv
See Nextclade docs for more details on usage, inputs, and outputs if you would
like to customize the rules:
https://docs.nextstrain.org/projects/nextclade/page/user/nextclade-cli.html
"""

rule nextclade_classify:
    """
    Classifies sequences into clades using Nextclade
    """
    input:
        sequences="results/sequences_all.fasta",
        dataset="../nextclade/dataset",
    output:
        nextclade_tsv="data/nextclade_results/nextclade.tsv",
    shell:
        """
        nextclade run \
          --input-dataset {input.dataset} \
          --output-tsv {output.nextclade_tsv} \
          --silent \
          {input.sequences}
        """

rule select_nextclade_columns:
    """
    Select the relevant columns from the nextclade results
    """
    input:
        nextclade_tsv="data/nextclade_results/nextclade.tsv",
    output:
        nextclade_subtypes="data/nextclade_clades.tsv",
    params:
        id_field=config["curate"]["id_field"],
        nextclade_field="clade_membership",
    shell:
        """
        echo "{params.id_field},{params.nextclade_field}" \
        | tr ',' '\t' \
        > {output.nextclade_subtypes}

        tsv-select -H -f "seqName,clade" {input} \
        | awk 'NR>1 {{print}}' \
        >> {output.nextclade_subtypes}
        """

rule append_nextclade_columns:
    """
    Append the nextclade results to the metadata
    """
    input:
        metadata="data/raw_metadata_all.tsv",
        nextclade_subtypes="data/nextclade_clades.tsv",
    output:
        metadata_all="results/metadata_all.tsv",
    params:
        id_field=config["curate"]["id_field"],
        nextclade_field="clade_membership",
    shell:
        """
        tsv-join -H \
            --filter-file {input.nextclade_subtypes} \
            --key-fields {params.id_field} \
            --append-fields {params.nextclade_field} \
            --write-all ? \
            {input.metadata} \
        > {output.metadata_all}
        """
