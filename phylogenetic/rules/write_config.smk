"""
This part of the workflow writes run time configuration to a YAML file.

OUTPUTS:

    results/run_config.yaml
"""

rule write_config:
    output:
        config = "results/run_config.yaml",
    log:
        "logs/write_config.txt",
    benchmark:
        "benchmarks/write_config.txt",
    run:
        import yaml
        with open(output.config, 'w') as f:
            yaml.dump(config, f, sort_keys=False)
