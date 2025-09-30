"""
This part of the workflow deals with configuration.

OUTPUTS:

    results/run_config.yaml
"""
from textwrap import dedent


def main():
    validate_config()
    write_config("results/run_config.yaml")


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


def indented_list(xs, prefix):
    return f"\n{prefix}".join(xs)


main()
