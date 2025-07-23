"""
This part of the workflow validates the configuration.
"""

# Check for deprecated "subsampling" key
if "subsampling" in config:
    raise ValueError(
        "The 'subsampling' configuration key is no longer supported. "
        "Please rename it to 'subsample' and update the format to match "
        "the augur subsample --config schema."
    )
