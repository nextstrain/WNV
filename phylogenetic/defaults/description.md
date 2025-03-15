We gratefully acknowledge the authors, originating and submitting laboratories of the genetic sequences and metadata for sharing their work. Please note that although data generators have generously shared data in an open fashion, that does not mean there should be free license to publish on this data. Data generators should be cited where possible and collaborations should be sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if uncertain.

Special thanks to individuals at the [Northwest Pathogen Genomics Center of Excellence](https://github.com/NW-PaGe) and [Grubaugh lab](https://grubaughlab.com/) for comments, code and suggestions.

**We maintain four views of WNV evolution:**

The first view is [`wnv/global`](https://next.nextstrain.org/WNV/global/), which focuses on the broader viral diversity for all WNV sequences submitted to GenBank that contain at least 75% of the genome length. Sequences are aligned to the reference sequence [AF260968](https://www.ncbi.nlm.nih.gov/nuccore/AF260968), which is the first WNV L1 (cluster 1) strain recovered in Egypt from 1951 ([Mencattelli, et al, 2023](https://doi.org/10.1038/s41467-023-42185-7)).

The second view is [`wnv/wa`](https://next.nextstrain.org/WNV/wa/), which focuses on WNV sequences from Washington State, with tiered subsampling from Washington, surrounding states, and across the USA. Sequences are aligned to reference sequence [AF481864](https://www.ncbi.nlm.nih.gov/nuccore/AF481864), a non-USA WNV sequence most closely related to the sequences isolated from New York in 1999 ([Hadfield et al, 2019](https://doi.org/10.1371/journal.ppat.1008042))

The third view is [`wnv/lineage-1A`](https://next.nextstrain.org/WNV/lineage-1A/), which focuses on the global lineage 1A. Sequences are aligned to RefSeq reference [NC_009942](https://www.ncbi.nlm.nih.gov/nuccore/NC_001563), and the phylogenetic tree is outgroup-rooted using a near Lineage-1B sequence [KX394399](https://www.ncbi.nlm.nih.gov/nuccore/KX394399).

The fourth view is [`wnv/lineage-2`](https://next.nextstrain.org/WNV/lineage-2/), which focuses on a global lineage 2. Sequences are aligned to the RefSeq reference [NC_001563](https://www.ncbi.nlm.nih.gov/nuccore/NC_001563).

#### Underlying data

We curate sequence data and metadata from NCBI as starting point for our analyses. For global lineage designations, we query [pathoplexus](https://pathoplexus.org/) for lineage assignments and exclusively work with NCBI-sourced records at this time. Curated sequences and metadata are available as flat files at:

* [data.nextstrain.org/files/workflows/WNV/sequences.fasta.zst](https://data.nextstrain.org/files/workflows/WNV/sequences.fasta.zst)
* [data.nextstrain.org/files/workflows/WNV/metadata.tsv.zst](https://data.nextstrain.org/files/workflows/WNV/metadata.tsv.zst)
