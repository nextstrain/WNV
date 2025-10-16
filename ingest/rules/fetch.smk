"""
This part of the workflow handles fetching sequences and metadata from Pathoplexus.

REQUIRED INPUTS:

    None

OUTPUTS:

    data/sequences.ndjson
    data/ncbi_entrez.ndjson

"""
workflow.global_resources.setdefault("concurrent_deploys", 2)

###########################################################################
####################### 1. Fetch from Pathoplexus #########################
###########################################################################

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

###########################################################################
########################## 2. Fetch from Entrez ###########################
###########################################################################


rule fetch_from_ncbi_entrez:
    params:
        term=config["entrez_search_term"],
    output:
        genbank="data/genbank.gb",
    # Allow retries in case of network errors
    retries: 5
    benchmark:
        "benchmarks/fetch_from_ncbi_entrez.txt"
    log:
        "logs/fetch_from_ncbi_entrez.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        {workflow.basedir}/../shared/vendored/scripts/fetch-from-ncbi-entrez \
            --term {params.term:q} \
            --output {output.genbank:q}
        """


rule parse_genbank_to_ndjson:
    input:
        genbank="data/genbank.gb",
    output:
        ndjson="data/ncbi_entrez.ndjson",
    benchmark:
        "benchmarks/parse_genbank_to_ndjson.txt"
    log:
        "logs/parse_genbank_to_ndjson.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        bio json --lines {input.genbank:q} \
          | jq -c '
              {{
                accession: .record.accessions[0],
                strain:    .record.strain[0],
                isolate:   .record.isolate[0],
              }}
            ' > {output.ndjson:q}
        """
