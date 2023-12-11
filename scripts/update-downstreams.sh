#!/bin/sh

# Script to update downstream/child repositories with this submodule
# https://github.com/os-climate/github/blob/main/scripts/update-downstreams.sh

# Variables
REPOSITORY_LIST="scripts/repositories.txt"

# Pre-flight checks
GIT_CMD=$(which git)
if [ ! -x "$GIT_CMD" ]; then
    echo "Error: GIT command was not found in PATH"; exit 1
elif [ ! -f "$REPOSITORY_LIST" ]; then
    echo "Error: missing repository list $REPOSITORY_LIST"; exit 1
fi

echo "Updating repositories with latest commit on main branch..."
HASH=$(git log -n 1 main --pretty=format:"%H")
echo "Last commit: $HASH"
echo "Parsing repo list: $REPOSITORY_LIST"
while IFS= read -r REPO < "$REPOSITORY_LIST"; do
    echo "Processing: $REPO"
done
