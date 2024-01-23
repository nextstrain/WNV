"""
This part of the workflow handles transforming the data into standardized
formats and expects input file

    sequences_ndjson = "data/sequences_{serotype}.ndjson"

This will produce output files as

    metadata = "data/metadata_{serotype}.tsv"
    sequences = "data/sequences_{serotype}.fasta"

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


rule curate:
    input:
        #sequences_ndjson="data/sequences_{serotype}.ndjson",
        sequences_ndjson="data/genbank_all.ndjson",
        all_geolocation_rules="data/all-geolocation-rules.tsv",
    output:
        metadata="data/metadata_{serotype}.tsv",
        sequences="data/sequences_{serotype}.fasta",
    log:
        "logs/curate_{serotype}.txt",
    params:
        field_map=config["curate"]["field_map"],
        strain_regex=config["curate"]["strain_regex"],
        strain_backup_fields=config["curate"]["strain_backup_fields"],
        date_fields=config["curate"]["date_fields"],
        expected_date_formats=config["curate"]["expected_date_formats"],
        articles=config["curate"]["titlecase"]["articles"],
        abbreviations=config["curate"]["titlecase"]["abbreviations"],
        titlecase_fields=config["curate"]["titlecase"]["fields"],
        authors_field=config["curate"]["authors_field"],
        authors_default_value=config["curate"]["authors_default_value"],
        abbr_authors_field=config["curate"]["abbr_authors_field"],
        annotations=config["curate"]["annotations"],
        annotations_id=config["curate"]["annotations_id"],
        metadata_columns=config["curate"]["metadata_columns"],
        id_field=config["curate"]["id_field"],
        sequence_field=config["curate"]["sequence_field"],
    shell:
        """
        (cat {input.sequences_ndjson} \
            | ./bin/transform-field-names \
                --field-map {params.field_map} \
            | augur curate normalize-strings \
            | ./bin/transform-strain-names \
                --strain-regex {params.strain_regex} \
                --backup-fields {params.strain_backup_fields} \
            | ./bin/transform-date-fields \
                --date-fields {params.date_fields} \
                --expected-date-formats {params.expected_date_formats} \
            | ./bin/transform-genbank-location \
            | ./bin/transform-string-fields \
                --titlecase-fields {params.titlecase_fields} \
                --articles {params.articles} \
                --abbreviations {params.abbreviations} \
            | ./bin/transform-authors \
                --authors-field {params.authors_field} \
                --default-value {params.authors_default_value:q} \
                --abbr-authors-field {params.abbr_authors_field} \
            | ./bin/apply-geolocation-rules \
                --geolocation-rules {input.all_geolocation_rules} \
            | ./bin/transform-state-names \
            | ./bin/post_process_metadata.py \
            | ./bin/merge-user-metadata \
                --annotations {params.annotations} \
                --id-field {params.annotations_id} \
            | ./bin/ndjson-to-tsv-and-fasta \
                --metadata-columns {params.metadata_columns} \
                --metadata {output.metadata} \
                --fasta {output.sequences} \
                --id-field {params.id_field} \
                --sequence-field {params.sequence_field} ) 2>> {log}
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
