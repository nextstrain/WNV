rule all:
    input:
        #auspice_tree = "auspice/WNV_NA_tree.json",
        #auspice_meta = "auspice/WNV_NA_meta.json",
        auspice = "auspice/WNV-nextstrain_NA.json"

rule files:
    params:
        input_fasta = "ingest/data/sequences_all.fasta",
        input_metadata = "ingest/data/metadata_all.tsv",
        reference = "config/reference.gb",
        auspice_config = "config/auspice_config.json",
        lat_longs = "config/lat_longs.tsv"

files = rules.files.params

# rule parse:
#     message:
#         "Parsing {input.sequences}, {input.metadata} and forming FASTA + metadata TSV"
#     input:
#         sequences = files.input_fasta,
#         metadata = files.input_metadata
#     output:
#         sequences = "results/sequences.fasta",
#         metadata = "results/metadata_sans_authors.tsv"
#     shell:
#         """
#         python ./scripts/parse_fasta_csv.py {input.sequences} {input.metadata} {output.sequences} {output.metadata}
#         """

rule add_authors:
    message:
        "Adding authors to {input.metadata} -> {output.metadata} by collecting info from ENTREZ"
    input:
        metadata = "ingest/data/metadata_all.tsv"
    output:
        metadata = "results/metadata.tsv"
    shell:
        """
        python ./scripts/add_authors.py {input.metadata} {output.metadata}
        """

rule create_colors:
    message:
        "Creating custom color scale in {output.colors}"
    input:
        #metadata = rules.parse.output.metadata,
        metadata = "ingest/data/metadata_all.tsv"
    output:
        colors = "results/colors.tsv"
    shell:
        """
        python ./scripts/make_colors.py {input.metadata} {output.colors}
        """

rule create_lat_longs:
    message:
        "Creating lat/longs in {output.lat_longs}"
    input:
        #metadata = rules.parse.output.metadata,
        metadata = "ingest/data/metadata_all.tsv"
    output:
        lat_longs = "results/lat_longs.tsv"
    shell:
        """
        python ./scripts/create_lat_longs.py {input.metadata} {output.lat_longs}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        #sequences = rules.parse.output.sequences,
        sequences = "ingest/data/sequences_all.fasta",
        reference = files.reference
    output:
        alignment = "results/aligned.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-name "NC_009942" \
            --output {output.alignment} \
            --fill-gaps
            #--reference-sequence {input.reference} \
        """

rule tree:
    message: "Building tree"
    input:
        #alignment = rules.align.output.alignment
        alignment = "results/aligned.fasta"
    output:
        tree = "results/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --method raxml \
            --nthreads auto
        """

rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
          - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
        """
    input:
        #tree = rules.tree.output.tree,
        tree = "results/tree_raw.nwk",
        #alignment = rules.align.output,
        alignment = "results/aligned.fasta",
        #metadata = rules.parse.output.metadata
        metadata = "data/headers.csv"
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    params:
        coalescent = "opt",
        date_inference = "marginal",
        clock_filter_iqd = 4
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --output-node-data {output.node_data} \
            --timetree \
            --coalescent {params.coalescent} \
            --date-confidence \
            --root AF481864
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        #tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        #alignment = rules.align.output
        alignment = "results/aligned.fasta"
    output:
        node_data = "results/nt_muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        #tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        #node_data = rules.ancestral.output.node_data,
        node_data = "results/nt_muts.json",
        reference = files.reference
    output:
        node_data = "results/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.reference} \
            --output {output.node_data} \
        """

rule traits:
    message: "Inferring ancestral traits for {params.columns!s}"
    input:
        #tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        #metadata = rules.parse.output.metadata
        metadata = "data/headers.csv"
    output:
        node_data = "results/traits.json",
    params:
        columns = "state lineage"
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output {output.node_data} \
            --columns {params.columns} \
            --confidence
        """

# rule export:
#     message: "Exporting data files for for auspice using V1 JSON schema"
#     input:
#         tree = rules.refine.output.tree,
#         metadata = rules.add_authors.output.metadata,
#         branch_lengths = rules.refine.output.node_data,
#         traits = rules.traits.output.node_data,
#         nt_muts = rules.ancestral.output.node_data,
#         aa_muts = rules.translate.output.node_data,
#         colors = rules.create_colors.output.colors,
#         lat_longs = rules.create_lat_longs.output.lat_longs,
#         auspice_config = files.auspice_config
#     output:
#         auspice_tree = rules.all.input.auspice_tree,
#         auspice_meta = rules.all.input.auspice_meta
#     shell:
#         """
#         augur export v1\
#             --tree {input.tree} \
#             --metadata {input.metadata} \
#             --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
#             --colors {input.colors} \
#             --auspice-config {input.auspice_config} \
#             --lat-longs {input.lat_longs} \
#             --output-tree {output.auspice_tree} \
#             --output-meta {output.auspice_meta}
#         """

rule export_v2:
    message: "Exporting data files for for auspice using V2 JSON schema"
    input:
        # tree = rules.refine.output.tree,
        tree = "results/tree.nwk",
        # metadata = rules.add_authors.output.metadata,
        metadata = "data/headers.csv",
        # branch_lengths = rules.refine.output.node_data,
        branch_lengths = "results/branch_lengths.json",
        # traits = rules.traits.output.node_data,
        traits = "results/traits.json",
        # nt_muts = rules.ancestral.output.node_data,
        nt_muts = "results/nt_muts.json",
        # aa_muts = rules.translate.output.node_data,
        aa_muts = "results/aa_muts.json",
        # colors = rules.create_colors.output.colors,
        colors = "results/colors.tsv",
        # lat_longs = rules.create_lat_longs.output.lat_longs,
        lat_longs = "results/lat_longs.tsv",
        auspice_config = "config/auspice_config_v2.json"
    #output:
        #auspice = "auspice/WNV-nextstrain_NA.json"
    output:
        auspice = "auspice/WNV-nextstrain_NA.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --auspice-config {input.auspice_config} \
            --lat-longs {input.lat_longs} \
            --output {output.auspice}
        """

rule clean:
    message: "Removing directories: {params}"
    params:
        "results ",
        "auspice"
    shell:
        "rm -rfv {params}"
