# OS-Climate

## Github Actions and shared linting

This repository shares GitHub Actions, workflows, linting settings, etc.

It should be configured as a sub-module inside other repositories.

Use the commands below at the top-level of the child repository:

    git submodule add <git@github.com>:os-climate/github.git .github
    ln -s .github/.pre-commit-config.yaml .pre-commit-config.yaml

The following files exist to aid propagation of updates:

    scripts/repositories.txt
    scripts/update-downstreams.sh

These are used to update the children to the latest commit/version.
