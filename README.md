# OS-Climate

## Shared DevOps Tooling, including linting tools, GitHub Actions

This repository shares common GitHub Actions, workflows, linting settings, etc.

Deployment is automated using a single GitHub workflow, defined in this file:

[workflows/bootstrap.yaml](workflows/bootstrap.yaml)

This runs weekly to ensure downstream repositories always hold the latest content.
