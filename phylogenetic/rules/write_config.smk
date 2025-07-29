"""
This part of the workflow writes run time configuration to a YAML file.

OUTPUTS:

    results/{build}/run_config.yaml
"""

rule write_config:
    output:
        config = f"results/{build}/run_config.yaml",
    log:
        f"logs/{build}/write_config.txt",
    benchmark:
        f"benchmarks/{build}/write_config.txt",
    run:
        import yaml
        with open(output.config, 'w') as f:
            yaml.dump(config, f, sort_keys=False)
