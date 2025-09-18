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


def main():
    validate_config()
    write_config()


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


def write_config():
    """
    Write Snakemake's 'config' variable to a file.

    This is useful for debugging purposes.
    """
    timestamp = datetime.now().astimezone().strftime("%Y-%m-%dT%H%M%S.%f")
    path = f"results/run_configs/{timestamp}.yaml"

    os.makedirs(os.path.dirname(path), exist_ok=True)

    with open(path, 'w') as f:
        yaml.dump(config, f, sort_keys=False)

    print(f"Saved current run config to {path!r}.", file=sys.stderr)


def indented_list(xs, prefix):
    return f"\n{prefix}".join(xs)


def conditional(option, argument):
    """Used for config-defined arguments whose presence necessitates a command-line option
    (e.g. --foo) prepended and whose absence should result in no option/arguments in the CLI command.
    *argument* can be falsey, in which case an empty string is returned (i.e. "don't pass anything
    to the CLI"), or a *list* or *string* or *number* in which case a flat list of options/args is returned,
    or *True* in which case a list of a single element (the option) is returned.
    Any other argument type is a WorkflowError
    """
    if not argument:
        return ""
    if argument is True: # must come before `isinstance(argument, int)` as bool is a subclass of int
        return [option]
    if isinstance(argument, list):
        return [option, *argument]
    if isinstance(argument, int) or isinstance(argument, float) or isinstance(argument, str):
        return [option, argument]
    raise WorkflowError(f"Workflow function conditional() received an argument value of unexpected type: {type(argument).__name__}")


main()
