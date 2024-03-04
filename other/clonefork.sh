#!/usr/bin/env bash

### Script to bulk clone/fork a GitHub organisation's repositories ###

set -o pipefail
# set -x

### Variables ###

SOURCE_GITHUB_ORG="os-climate"
TARGET_GITHUB_ORG="modeseven-os-climate"
PARALLEL_THREADS="8"
echo "Parallel threads: $PARALLEL_THREADS"

### Checks ###

GITHUB_CLI=$(which gh)
if [ ! -x "$GITHUB_CLI" ]; then
    echo "The GitHub CLI was not found in your PATH"; exit 1
fi

if [ $# -ne 1 ]; then
    echo "Usage: $0    [ clone | fork ]"; exit 1
else
    OPERATION="$1"
fi

### Functions ###

auth_check() {
    if ! ("$GITHUB_CLI" auth status); then
        echo "You are not logged into GitHub"
        echo "Use the command: gh auth login"; exit 1
    fi
}

### Operations m###

if [ "$OPERATION" = "clone" ]; then
    auth_check
    "$GITHUB_CLI" repo list "$SOURCE_GITHUB_ORG" \
        --limit 4000 --json nameWithOwner --jq '.[].nameWithOwner' | \
        parallel -j "$PARALLEL_THREADS" "$GITHUB_CLI" repo clone
elif [ "$OPERATION" = "fork" ]; then
    auth_check
    "$GITHUB_CLI" repo list "$SOURCE_GITHUB_ORG" \
        --limit 4000 --json nameWithOwner --jq '.[].nameWithOwner' | \
        parallel --j "$PARALLEL_THREADS" "$GITHUB_CLI" repo fork \
        --default-branch-only --org "$TARGET_GITHUB_ORG" --clone --remote
else
    echo "Invalid operation specified: $OPERATION"
    echo "Valid options are: clone, fork"; exit 1
fi
