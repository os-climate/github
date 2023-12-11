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
if [ "$ERRORS" == "true" ]; then
    echo "Error: fix repository listing and try again"; exit 1
fi

echo "Parsing repo list: $REPOSITORY_LIST"
while IFS= read -r REPO ; do
    echo "Processing: $REPO"
    # Change directory safely
    cd "$REPO" || exit
    git checkout main; git pull
done < "$REPOSITORY_LIST"
