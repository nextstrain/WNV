"""
This part of the workflow handles fetching sequences and metadata from Pathoplexus.

REQUIRED INPUTS:

    None

OUTPUTS:

    ndjson = data/sequences.ndjson

"""
workflow.global_resources.setdefault("concurrent_deploys", 2)

rule download_ppx_seqs:
    output:
        sequences= "data/ppx_sequences.fasta",
    params:
        sequences_url=config["ppx_fetch"]["seqs"],
    # Allow retries in case of network errors
    retries: 5
    benchmark:
        "benchmarks/download_ppx_seqs.txt"
    log:
        "logs/download_ppx_seqs.txt"
    shell:
        """
        curl {params.sequences_url} -o {output.sequences}
        """

rule download_ppx_meta:
    output:
        metadata= "data/ppx_metadata.csv"
    params:
        metadata_url=config["ppx_fetch"]["meta"],
        fields = ",".join(config["ppx_metadata_fields"])
    # Allow retries in case of network errors
    retries: 5
    benchmark:
        "benchmarks/download_ppx_meta.txt"
    log:
        "logs/download_ppx_meta.txt"
    shell:
        """
        curl '{params.metadata_url}&fields={params.fields}' -o {output.metadata}
        """

rule format_ppx_ndjson:
    input:
        sequences = "data/ppx_sequences.fasta",
        metadata = "data/ppx_metadata.csv",
    output:
        ndjson = "data/sequences.ndjson",
    log:
        "logs/format_ppx_ndjson.txt"
    benchmark:
        "benchmarks/format_ppx_ndjson.txt"
    shell:
        """
        augur curate passthru \
            --metadata {input.metadata} \
            --fasta {input.sequences} \
            --seq-id-column accessionVersion \
            --seq-field sequence \
            --unmatched-reporting warn \
            --duplicate-reporting warn \
            2> {log} > {output.ndjson}
        """
