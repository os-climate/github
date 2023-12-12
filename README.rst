# OS-Climate

## Shared DevOps Tooling, including linting tools, GitHub Actions

This repository shares common GitHub Actions, workflows, linting settings, etc.

It is invoked/updated by a single GitHub workflow, defined in:

.. literalinclude:: workflows/bootstrap.yaml
   :language: YAML

This runs weekly to ensure OS-Climate repositories always hold the latest content.
