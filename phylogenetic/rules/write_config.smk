"""
This part of the workflow writes run time configuration to a YAML file.

OUTPUTS:

    results/run_configs/{timestamp}.yaml
"""
import os
import sys
import yaml
from datetime import datetime

timestamp = datetime.now().astimezone().strftime("%Y-%m-%dT%H%M%S.%f")
RUN_CONFIG = f"results/run_configs/{timestamp}.yaml"

os.makedirs(os.path.dirname(RUN_CONFIG), exist_ok=True)

with open(RUN_CONFIG, 'w') as f:
    yaml.dump(config, f, sort_keys=False)

print(f"Saved current run config to {RUN_CONFIG!r}.", file=sys.stderr)
