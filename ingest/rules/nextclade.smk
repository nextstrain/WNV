"""
This part of the workflow handles running Nextclade on the curated metadata
and sequences.
REQUIRED INPUTS:
    metadata    = data/subset_metadata.tsv
    sequences   = data/sequences_all.fasta
    nextclade_datasets = ../nextclade/dataset
OUTPUTS:
    metadata        = data/metadata_all.tsv
    nextclade       = data/nextclade_clades.tsv
See Nextclade docs for more details on usage, inputs, and outputs if you would
like to customize the rules:
https://docs.nextstrain.org/projects/nextclade/page/user/nextclade-cli.html
"""

rule pathoplexus_classify:
    """
    Pulls global lineage calls from Pathoplexus API
    """
    output:
        pathoplexus_tsv="data/pathoplexus_results/global_lineages.tsv",
    params:
        URL=config["pathoplexus"]["URL"],
        fields=config["pathoplexus"]["fields"],
        accession_field=config["pathoplexus"]["accession_field"],
        id_field=config["curate"]["output_id_field"],
    shell:
        r"""
        curl "{params.URL}?dataFormat=TSV&downloadAsFile=false&fields={params.fields}" \
        | tsv-filter -H --not-empty {params.accession_field} \
        | uniq \
        | csvtk -t rename -f {params.accession_field} -n {params.id_field} \
        >  {output.pathoplexus_tsv}
        """

rule select_USA_potential_samples:
    """
    Select 1A or "unassigned" sequences from the USA
    """
    input:
        sequences="results/sequences.fasta",
        pathoplexus_tsv="data/pathoplexus_results/global_lineages.tsv",
    output:
        potential_1A_samples="data/pathoplexus_results/potential_1A_samples.tsv",
        sequences="data/potential_1A_sequences.fasta",
    params:
        id_field=config["curate"]["output_id_field"],
    shell:
        r"""
        tsv-filter -H \
          --not-regex 'lineage:^(1B|2|3|4|5|6|7|8)$' \
          {input.pathoplexus_tsv} \
        > {output.potential_1A_samples}

        augur filter \
            --sequences {input.sequences} \
            --metadata {output.potential_1A_samples} \
            --metadata-id-columns {params.id_field} \
            --output-sequences {output.sequences}
        """

rule nextclade_classify:
    #Classifies sequences into clades using Nextclade
    input:
        sequences="data/potential_1A_sequences.fasta",
        dataset=config["nextclade"]["nextclade_dataset_path"],
    output:
        nextclade_tsv="data/nextclade_results/nextclade.tsv",
    threads: workflow.cores,
    shell:
        """
        nextclade3 run \
          --input-dataset {input.dataset} \
          --output-tsv {output.nextclade_tsv} \
          --jobs {threads:q} \
          --silent \
          {input.sequences}
        """

rule select_nextclade_columns:
    #Select the relevant columns from the nextclade results
    input:
        nextclade_tsv="data/nextclade_results/nextclade.tsv",
    output:
        nextclade_subtypes="data/nextclade_clades.tsv",
    params:
        id_field=config["curate"]["output_id_field"],
        nextclade_field=config["nextclade"]["nextclade_field"],
    shell:
        """
        echo "{params.id_field},{params.nextclade_field}" \
        | tr ',' '\t' \
        > {output.nextclade_subtypes}

        csvtk cut -t -f "seqName,clade" {input} \
        | awk 'NR>1 {{print}}' \
        >> {output.nextclade_subtypes}
        """

rule append_nextclade_columns:
    """
    Append the nextclade results to the metadata
    """
    input:
        metadata="data/subset_metadata.tsv",
        nextclade_subtypes="data/nextclade_clades.tsv",
    output:
        metadata_all="data/metadata_nextclade.tsv",
    params:
        id_field=config["curate"]["output_id_field"],
        nextclade_id_field=config["nextclade"]["nextclade_id"],
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                nextclade={input.nextclade_subtypes:q} \
            --metadata-id-columns \
                metadata={params.id_field:q} \
                nextclade={params.nextclade_id_field:q} \
            --output-metadata {output.metadata_all:q} \
            --no-source-columns
        """

rule append_pathoplexus_columns:
    """
    Append the pathoplexus results to the metadata
    """
    input:
        metadata="data/metadata_nextclade.tsv",
        pathoplexus_tsv="data/pathoplexus_results/global_lineages.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        id_field=config["curate"]["output_id_field"],
        pathoplexus_field=config["curate"]["output_id_field"],
    shell:
        r"""
        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                pathoplexus={input.pathoplexus_tsv:q} \
            --metadata-id-columns \
                metadata={params.id_field:q} \
                pathoplexus={params.pathoplexus_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns
        """
