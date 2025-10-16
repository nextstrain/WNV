"""
This part of the workflow handles the curation of data from Pathoplexus

REQUIRED INPUTS:

    sequences_ndjson = data/sequences.ndjson

OUTPUTS:

    metadata         = data/subset_metadata.tsv
    sequences        = results/sequences.fasta

"""


def format_field_map(field_map: dict[str, str]) -> str:
    """
    Format dict to `"key1"="value1" "key2"="value2"...` for use in shell commands.
    """
    return " ".join([f'"{key}"="{value}"' for key, value in field_map.items()])

rule curate:
    input:
        sequences_ndjson="data/sequences.ndjson",
        geolocation_rules=config["curate"]["local_geolocation_rules"],
        annotations=config["curate"]["annotations"],
        manual_mapping="defaults/host_hostgenus_hosttype_map.tsv",
    output:
        metadata= "data/all_metadata.tsv",
        sequences="results/sequences.fasta",
    log:
        "logs/curate.txt",
    benchmark:
        "benchmarks/curate.txt",
    params:
        field_map=format_field_map(config["curate"]["field_map"]),
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations_id=config["curate"]["annotations_id"],
        id_field=config["curate"]["output_id_field"],
        sequence_field=config["curate"]["output_sequence_field"],
    shell:
        """
        (cat {input.sequences_ndjson} \
            | augur curate rename \
                --field-map {params.field_map} \
            | augur curate normalize-strings \
            | augur curate format-dates \
                --date-fields {params.date_fields} \
                --expected-date-formats {params.expected_date_formats} \
            | augur curate titlecase \
                --titlecase-fields {params.titlecase_fields} \
                --articles {params.articles} \
                --abbreviations {params.abbreviations} \
            | augur curate abbreviate-authors \
                --authors-field {params.authors_field} \
                --default-value {params.authors_default_value:q} \
                --abbr-authors-field {params.abbr_authors_field} \
            | augur curate apply-geolocation-rules \
                --geolocation-rules {input.geolocation_rules} \
            | ./scripts/transform-state-names \
            | ./scripts/post_process_metadata.py \
            | ./scripts/transform-new-fields \
                --map-tsv {input.manual_mapping} \
                --map-id host \
                --metadata-id host \
                --map-fields host_genus host_type \
                --pass-through true \
            | augur curate apply-record-annotations \
                --annotations {input.annotations} \
                --id-field {params.annotations_id} \
                --output-metadata {output.metadata} \
                --output-fasta {output.sequences} \
                --output-id-field {params.id_field} \
                --output-seq-field {params.sequence_field} ) 2>> {log}
        """
rule add_accession_urls:
    """Add columns to metadata
    Notable columns:
    - PPX_accession__url: URL linking to the Pathoplexus record.
    - INSDC_accession__url: URL linking to the NCBI GenBank record.
    - url: URL linking to the NCBI GenBank record (kept for backwards compatibility).
    """
    input:
        metadata = "data/all_metadata.tsv"
    output:
        metadata = temp("data/all_metadata_added.tsv")
    params:
        pathoplexus_accession=config['curate']['pathoplexus_accession'],
        pathoplexus_accession_url=config['curate']['pathoplexus_accession'] + "__url",
        insdc_accession=config['curate']['insdc_accession'],
        insdc_accession_url=config['curate']['insdc_accession'] + "__url",
    shell:
        """
        cat {input.metadata} \
            | csvtk mutate2 -t \
                -n {params.pathoplexus_accession_url} \
                -e '"https://pathoplexus.org/seq/" + ${params.pathoplexus_accession}' \
            | csvtk mutate2 -t \
                -n {params.insdc_accession_url} \
                -e '"https://www.ncbi.nlm.nih.gov/nuccore/" + ${params.insdc_accession}' \
            | csvtk mutate2 -t \
                -n url \
                -e '"https://www.ncbi.nlm.nih.gov/nuccore/" + ${params.insdc_accession}' \
        > {output.metadata}
        """

rule subset_metadata:
    input:
        metadata="data/all_metadata_added.tsv",
    output:
        metadata="data/subset_metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    shell:
        """
        csvtk cut -t -f {params.metadata_fields} \
            {input.metadata} > {output.metadata}
        """

rule extract_open_data:
    input:
        metadata = "results/metadata.tsv",
        sequences = "results/sequences.fasta"
    output:
        metadata = "results/metadata_open.tsv",
        sequences = "results/sequences_open.fasta"
    benchmark:
        "benchmarks/extract_open_data.txt"
    log:
        "logs/extract_open_data.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --metadata {input.metadata:q} \
            --sequences {input.sequences:q} \
            --metadata-id-columns accession \
            --exclude-where "dataUseTerms=RESTRICTED" \
            --output-metadata {output.metadata:q} \
            --output-sequences {output.sequences:q}
        """

rule compress:
    input:
        file="{a_file}",
    output:
        file_compressed="{a_file}.zst",
    shell:
        """
        zstd -T0 -o {output.file_compressed} {input.file}
        """
