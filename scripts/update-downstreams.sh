#!/bin/sh

# Script to update downstream/child repositories with this submodule
# https://github.com/os-climate/github/blob/main/scripts/update-downstreams.sh

# Variables
REPOSITORY_LIST="scripts/repositories.txt"
INITIAL_DIR=$(pwd)

# Pre-flight checks
GIT_CMD=$(which git)
if [ ! -x "$GIT_CMD" ]; then
    echo "Error: GIT command was not found in PATH"; exit 1
elif [ ! -f "$REPOSITORY_LIST" ]; then
    echo "Error: missing repository list $REPOSITORY_LIST"; exit 1
fi

echo "Current working directory: $INITIAL_DIR"
echo "Updating repositories with latest commit on main branch..."
HASH=$(git log -n 1 main --pretty=format:"%H")
echo "Last commit: $HASH"

# Initially, check all the downstream repositories exist
while IFS= read -r REPO ; do
    ERRORS="false"
    if [ ! -d "$REPO" ]; then
        echo "Invalid path to repository: $REPO"
        ERRORS="true"
    fi
done < "$REPOSITORY_LIST"
if [ "$ERRORS" = "true" ]; then
    echo "Error: fix repository listing and try again"; exit 1
fi

echo "Parsing repo list: $REPOSITORY_LIST"
while IFS= read -r REPO ; do
    echo "Processing: $REPO"
    # Change directory safely
    cd "$REPO" || exit
    git checkout main; git pull
    # If pre-commit file exists, check if it needs updating
    if [ -f .pre-commit-config.yaml ] && [ -f .github/.pre-commit-config.yaml ]; then
        STATUS="$(cmp --silent .pre-commit-config.yaml .github/.pre-commit-config.yaml)"
        if [ "$STATUS" -ne 0 ]; then
            echo "Updating .pre-commit-config.yaml from upstream"
            rm .pre-commit-config.yaml
            cp .github/.pre-commit-config.yaml .pre-commit-config.yaml
        fi
    fi
done < "$REPOSITORY_LIST"
