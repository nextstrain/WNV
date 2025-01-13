#! /usr/bin/env python3

import argparse
import json
from sys import stdin, stdout


def parse_args():
    parser = argparse.ArgumentParser(
        description="Reformat a NCBI Virus metadata.tsv file for a pathogen build."
    )

    return parser.parse_args()


def _set_strain_name(record):
    """Replace spaces, dashes, and periods with underscores in strain name."""
    strain_name = record["strain"]

    return (
        strain_name.replace(" ", "_")
        .replace("-", "_")
        .replace(".", "_")
        .replace("(", "_")
        .replace(")", "_")
    )


def _set_url(record):
    """Set url column from accession"""
    return "https://www.ncbi.nlm.nih.gov/nuccore/" + str(record["accession"])


def main():
    args = parse_args()

    for index, record in enumerate(stdin):
        record = json.loads(record)
        record["strain"] = _set_strain_name(record)
        record["url"] = _set_url(record)
        stdout.write(json.dumps(record) + "\n")


if __name__ == "__main__":
    main()
