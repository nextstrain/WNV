# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes, and config value changes that may affect both the usage of the workflows and the outputs of the workflows.

## 2025

* 8 September 2025: Configuration resolved at run time is now written to a file under `results/run_configs`. [PR #102](https://github.com/nextstrain/WNV/pull/102) @victorlin
* 8 September 2025: The phylogenetic workflow configuration now expects a new structure with most configuration defined under a build-specific key. See `phylogenetic/defaults/config.yaml` as an example. **This is a breaking change.** [PR #102](https://github.com/nextstrain/WNV/pull/102) @victorlin
* 8 September 2025: The phylogenetic workflow now runs all Nextstrain-maintained builds by default. This can be adjusted by a new configuration option, `builds`. **This is a breaking change.** [PR #102](https://github.com/nextstrain/WNV/pull/102) @victorlin
* 8 September 2025: Support for manual subsampling by editing the file `phylogenetic/rules/subsampling_manual.smk` is no longer supported. **This is a breaking change.** [PR #102](https://github.com/nextstrain/WNV/pull/102) @victorlin
* 24 March 2025: Add frequencies panel @j23414
* 21 March 2025: Migrated WA specific config to NW-PaGe [PR#90] @j23414, @DOH-LMT2303, @DOH-PNT0303
* 18 March 2025: Rename "global" to "all-lineages, update various auspice_config settings @j23414
* 14 March 2025: Pushed from staging to live @j23414
* 11 March 2025: Added lineage-1A and lineage-2 phylogenetic trees [PR#61](https://github.com/nextstrain/WNV/pull/61) @j23414
* 5 March 2025: Adopt NW-PaGe README template to document Nextstrain analysis and scientific decisions [PR#76](https://github.com/nextstrain/WNV/pull/76) @DOH-LMT2303
* 23 February 2025: Adopt Avian-flu style merging of additional data during the phylogenetic workflow [PR#68](https://github.com/nextstrain/WNV/pull/68) @j23414
    * From a brief discussion with James Hadfield, the generic API pattern of merging additional data is solidified while the implementation details are still being hashed out in Zika and avian flu pipelines. @j23414 figured that we can update to the final settled decision later especially since the generic API pattern is easier to explain in documentation to other state labs.
* 19 February 2025: Derive URL column during ingest [PR#66](https://github.com/nextstrain/WNV/pull/66) @DOH-LMT2303
* 2 February 2025: Added manual date annotations for basel lineage-1A and lineage 2 samples [#PR63](https://github.com/nextstrain/WNV/pull/63) @j23414
* 20 January 2025: Update Ingest workflow to use new augur merge command [PR#60](https://github.com/nextstrain/WNV/pull/60) @DOH-LMT2303
* 13 January 2025: Update TSV and csvtk handling to align with pathogen repo guide [PR#58](https://github.com/nextstrain/WNV/pull/58) @DOH-LMT2303
* 13 January 2025: Switch to full_authors and authors fields to align with the pathogen repo guide [PR#56](https://github.com/nextstrain/WNV/pull/56) @DOH-LMT2303
* 20 January 2025: Global trees were already automated, added automation for WA-state phylogenetic tree [PR#54](https://github.com/nextstrain/WNV/pull/) @j23414
* 9 January 2025: Reduced minimum genome length to 75% to include more WA sequences without a noticable deteriation of phylogenetic trees [PR#52](https://github.com/nextstrain/WNV/pull/52) @DOH-LMT2303

## 2024

* 20 December 2024: Add documentation on decision points [PR#51](https://github.com/nextstrain/WNV/pull/51) @DOH-LMT2303
* 20 November 2024: Switch to use IQ-Tree as the faster phylogenetic tree builder [PR#47](https://github.com/nextstrain/WNV/pull/47) @j23414
* 19 November 2024: Enable multithreading to avoid the 6hr GH Action Timeout error [PR#45](https://github.com/nextstrain/WNV/pull/45) @j23414
* 18 November 2024: Add "Host Genus" and "Host Type" annotations to the phylogenetic tree [PR#42](https://github.com/nextstrain/WNV/pull/42) @DOH-LMT2303 @j23414
* 1 November 2024: Set molecular clock based on a literature search [PR#38](https://github.com/nextstrain/WNV/pull/38) @j23414 @DOH-LMT2303
* 25 October 2024: Separated out global tree and WA-specific configs [PR#30](https://github.com/nextstrain/WNV/pull/30) @j23414
* 16 October 2024: Enable filtering out lab host samples [PR#28](https://github.com/nextstrain/WNV/pull/28) @j23414
* 10 October 2024: Added automation for public global build and publish to staging [PR#13](https://github.com/nextstrain/WNV/pull/13),[PR#19](https://github.com/nextstrain/WNV/pull/19), [PR#22](https://github.com/nextstrain/WNV/pull/22) @joverlee521 @j23414
* 28 September 2024: Added logs and benchmarks across workflow rules [PR#14](https://github.com/nextstrain/WNV/pull/14)  @DOH-LMT2303
* 14 September 2024: Added description file [PR#10](https://github.com/nextstrain/WNV/pull/10) @j23414
* 16 August 2024: Used augur curate commands and various refactoring [PR#7](https://github.com/nextstrain/WNV/pull/7) @j23414
* 12 June 2024: Added initial Nextclade workflow for creating a Nextclade dataset to classify USA-based lineages [PR#4](https://github.com/nextstrain/WNV/pull/4) @j23414
* 14 March 2024: Updated the geolocation rules and latitutde longitude processing [PR#3](https://github.com/nextstrain/WNV/pull/3) @j23414
* 26 February 2024: Added generic subsampling rules and documentation [PR#1](https://github.com/nextstrain/WNV/pull/1), [PR#2](https://github.com/nextstrain/WNV/pull/2) @huddlej

## pre-2024

* The WNV workflows associated with the Hadfield paper was originally maintained at https://github.com/nextstrain/WNV, but was later renamed and archived at https://github.com/nextstrain/WNV-old .
* To update the pipeline and establish a collaboration between Nextstrain and WA-DOH, the WNV repository was initialy forked to https://github.com/NW-PaGe/WNV.
* Later on, to avoid duplicating work, the WNV repository was then mirrored back to https://github.com/nextstrain/WNV, and WA-DOH collaborators were added so they could contribute to the codebase directly.