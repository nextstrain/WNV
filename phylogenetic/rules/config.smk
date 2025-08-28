"""
This part of the workflow deals with configuration.

OUTPUTS:

    results/run_configs/{timestamp}.yaml
"""
import os
import sys
import yaml
from datetime import datetime
from textwrap import dedent


timestamp = datetime.now().astimezone().strftime("%Y-%m-%dT%H%M%S.%f")
RUN_CONFIG = f"results/run_configs/{timestamp}.yaml"


def main():
    validate_config()
    write_config(RUN_CONFIG)


def validate_config():
    """
    Validate the config.

    This could be improved with a schema definition file, but for now it serves
    to provide useful error messages for common user errors and effects of
    breaking changes.
    """
    # Validate 'builds'
    if invalid_builds := set(config["builds"]) - set(config["build_params"]):
        print(dedent(f"""\
            ERROR: The following names in 'builds' are not defined in 'build_params':

                {indented_list(invalid_builds, "            ")}

            Available builds are:

                {indented_list(config['build_params'], "            ")}
            """))
        exit(1)

    # Check for deprecated 'subsampling' keys
    for build in config["builds"]:
        if "subsampling" in config["build_params"][build]:
            print(dedent(f"""\
                ERROR: The 'subsampling' configuration key is no longer supported.

                Please rename it to 'subsample' and update the format to match
                the augur subsample --config structure:

                    <https://docs.nextstrain.org/projects/augur/en/stable/usage/cli/subsample.html#configuration>"""))
            exit(1)


def write_config(path):
    """
    Write Snakemake's 'config' variable to a file.

    This is used for the subsample rule and is generally useful for debugging.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)

    with open(path, 'w') as f:
        yaml.dump(config, f, sort_keys=False)

    print(f"Saved current run config to {path!r}.", file=sys.stderr)


def indented_list(xs, prefix):
    return f"\n{prefix}".join(xs)


main()
