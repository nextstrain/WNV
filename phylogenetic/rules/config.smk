"""
This part of the workflow deals with configuration.

OUTPUTS:

    results/run_config.yaml
"""
import os
import sys
import yaml
from textwrap import dedent


RUN_CONFIG = f"results/run_config.yaml"


def main():
    validate_config()
    resolve_config_paths()
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


def resolve_config_paths():
    """
    Update all file paths in config by passing them through resolve_config_path()
    """
    global config

    for build_name, build_config in config["build_params"].items():
        # config.<build>.reference
        build_config["reference"] = resolve_config_path(build_config["reference"])({})

        # config.<build>.export
        for key in ["description", "auspice_config"]:
            build_config["export"][key] = resolve_config_path(build_config["export"][key])({})

        # config.<build>.subsample
        subsample_path_keys = ["exclude", "include", "group_by_weights"]
        for sample_name, sample_config in build_config["subsample"]["samples"].items():
            for key in subsample_path_keys:
                if key in sample_config:
                    if isinstance(sample_config[key], list):
                        sample_config[key] = [resolve_config_path(path)({}) for path in sample_config[key]]
                    else:
                        sample_config[key] = resolve_config_path(sample_config[key])({})


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
