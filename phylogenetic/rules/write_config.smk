"""
This part of the workflow writes run time configuration to a YAML file.

OUTPUTS:

    results/run_config.yaml
"""
import os
import yaml

path = "results/run_config.yaml"

os.makedirs(os.path.dirname(path), exist_ok=True)

with open(path, 'w') as f:
    yaml.dump(config, f, sort_keys=False)
