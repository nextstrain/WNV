"""
This part of the workflow handles transforming the data into standardized
formats and expects input file

    sequences_ndjson = "data/sequences_{serotype}.ndjson"

This will produce output files as

    metadata = "results/metadata_{serotype}.tsv"
    sequences = "results/sequences_{serotype}.fasta"

Parameters are expected to be defined in `config.curate`.
"""


rule fetch_general_geolocation_rules:
    output:
        general_geolocation_rules="data/general-geolocation-rules.tsv",
    params:
        geolocation_rules_url=config["curate"]["geolocation_rules_url"],
    shell:
        """
        curl -fsSL --output {output.general_geolocation_rules} {params.geolocation_rules_url}
        """


rule concat_geolocation_rules:
    input:
        general_geolocation_rules="data/general-geolocation-rules.tsv",
        local_geolocation_rules=config["curate"]["local_geolocation_rules"],
    output:
        all_geolocation_rules="data/all-geolocation-rules.tsv",
    shell:
        """
        cat {input.general_geolocation_rules} {input.local_geolocation_rules} >> {output.all_geolocation_rules}
        """

def format_field_map(field_map: dict[str, str]) -> str:
    """
    Format dict to `"key1"="value1" "key2"="value2"...` for use in shell commands.
    """
    return " ".join([f'"{key}"="{value}"' for key, value in field_map.items()])

rule curate:
    input:
        sequences_ndjson="data/genbank.ndjson",
        all_geolocation_rules="data/all-geolocation-rules.tsv",
        annotations=config["curate"]["annotations"],
        manual_mapping="defaults/host_hostgenus_hosttype_map.tsv",
    output:
        metadata="data/raw_metadata_curated.tsv",
        sequences="results/sequences.fasta",
    log:
        "logs/curate.txt",
    benchmark:
        "benchmarks/curate.txt",
    params:
        field_map=format_field_map(config["curate"]["field_map"]),
        strain_regex=config["curate"]["strain_regex"],
        strain_backup_fields=config["curate"]["strain_backup_fields"],
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        genbank_location_field=config["curate"]["genbank_location_field"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations_id=config["curate"]["annotations_id"],
        metadata_columns=config["curate"]["metadata_columns"],
        id_field=config["curate"]["output_id_field"],
        sequence_field=config["curate"]["output_sequence_field"],
    shell:
        """
        (cat {input.sequences_ndjson} \
            | augur curate rename \
                --field-map {params.field_map} \
            | augur curate normalize-strings \
            | augur curate transform-strain-name \
                --strain-regex {params.strain_regex} \
                --backup-fields {params.strain_backup_fields} \
            | augur curate format-dates \
                --date-fields {params.date_fields} \
                --expected-date-formats {params.expected_date_formats} \
            | augur curate parse-genbank-location \
                --location-field {params.genbank_location_field} \
            | augur curate titlecase \
                --titlecase-fields {params.titlecase_fields} \
                --articles {params.articles} \
                --abbreviations {params.abbreviations} \
            | augur curate abbreviate-authors \
                --authors-field {params.authors_field} \
                --default-value {params.authors_default_value:q} \
                --abbr-authors-field {params.abbr_authors_field} \
            | augur curate apply-geolocation-rules \
                --geolocation-rules {input.all_geolocation_rules} \
            | ./scripts/transform-state-names \
            | ./scripts/post_process_metadata.py \
            | ./scripts/add-field-names \
                --metadata-columns {params.metadata_columns} \
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

rule subset_metadata:
    input:
        metadata="data/raw_metadata_curated.tsv",
    output:
        metadata="data/raw_metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    shell:
        """
        csvtk cut -f {params.metadata_fields} \
            {input.metadata} > {output.metadata}
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
