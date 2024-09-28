"""
This part of the workflow handles fetching sequences from various sources.
Uses `config.sources` to determine which sequences to include in final output.

Currently only fetches sequences from GenBank, but other sources can be
defined in the config. If adding other sources, add a new rule upstream
of rule `fetch_all_sequences` to create the file `data/{source}.ndjson` or the
file must exist as a static file in the repo.

Produces final output as

    sequences_ndjson = "data/sequences.ndjson"

"""
workflow.global_resources.setdefault("concurrent_deploys", 2)

rule fetch_ncbi_dataset_package:
    output:
        dataset_package = temp("data/ncbi_dataset.zip")
    retries: 5 # Requires snakemake 7.7.0 or later
    log:
        "logs/fetch_ncbi_dataset_package.txt"
    benchmark:
        "benchmarks/fetch_ncbi_dataset_package.txt"
    params:
        ncbi_taxon_id = config["ncbi_taxon_id"]
    shell:
        """
        datasets download virus genome taxon {params.ncbi_taxon_id} \
            --no-progressbar \
            --filename {output.dataset_package} 2>&1 | tee {log}
        """

# Note: This rule is not part of the default workflow!
# It is intended to be used as a specific target for users to be able
# to inspect and explore the full raw metadata from NCBI Datasets.
rule dump_ncbi_dataset_report:
    input:
        dataset_package="data/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv="data/ncbi_dataset_report_raw.tsv",
    shell:
        """
        dataformat tsv virus-genome \
            --package {input.dataset_package} > {output.ncbi_dataset_tsv}
        """

rule extract_ncbi_dataset_sequences:
    input:
        dataset_package = "data/ncbi_dataset.zip"
    output:
        ncbi_dataset_sequences = temp("data/ncbi_dataset_sequences.fasta")
    benchmark:
        "benchmarks/extract_ncbi_dataset_sequences.txt"
    shell:
        """
        unzip -jp {input.dataset_package} \
            ncbi_dataset/data/genomic.fna > {output.ncbi_dataset_sequences}
        """

rule format_ncbi_dataset_report:
    input:
        dataset_package = "data/ncbi_dataset.zip",
    output:
        ncbi_dataset_tsv = temp("data/ncbi_dataset_report.tsv")
    params:
        ncbi_dataset_fields = ",".join(config["ncbi_datasets_fields"]),
    benchmark:
        "benchmarks/format_ncbi_dataset_report.txt"
    shell:
        """
        dataformat tsv virus-genome \
            --package {input.dataset_package} \
            --fields {params.ncbi_dataset_fields:q} \
            --elide-header \
            | csvtk fix-quotes -Ht \
            | csvtk add-header -t -l -n {params.ncbi_dataset_fields} \
            | csvtk rename -t -f accession -n accession_version \
            | csvtk -t mutate -f accession_version -n accession -p "^(.+?)\." \
            | csvtk del-quotes -t \
            | tsv-select -H -f accession --rest last \
            > {output.ncbi_dataset_tsv}
        """


rule format_ncbi_datasets_ndjson:
    input:
        ncbi_dataset_sequences = "data/ncbi_dataset_sequences.fasta",
        ncbi_dataset_tsv = "data/ncbi_dataset_report.tsv",
    output:
        ndjson = "data/genbank.ndjson",
    log:
        "logs/format_ncbi_datasets_ndjson.txt"
    benchmark:
        "benchmarks/format_ncbi_datasets_ndjson.txt"
    shell:
        """
        augur curate passthru \
            --metadata {input.ncbi_dataset_tsv} \
            --fasta {input.ncbi_dataset_sequences} \
            --seq-id-column accession_version \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
            2> {log} > {output.ndjson}
        """
