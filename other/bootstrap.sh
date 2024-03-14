#!/usr/bin/env bash

### Script to bootstrap the OS-Climate DevOps environment ###

# set -eu -o pipefail
set -xv

### Variables ###

DEVOPS_REPO="git@github.com:os-climate/devops-toolkit.git"
PR_BRANCH="update-devops-tooling"

### Checks ###

GIT_CMD=$(which git)
if [ ! -x "$GIT_CMD" ]; then
    echo "GIT command was not found in PATH"; exit 1
fi

### Functions ###

change_dir_error() {
    echo "Could not change directory"; exit 1
}

check_for_local_branch() {
    BRANCH="$1"
    git show-ref --quiet refs/heads/"$BRANCH"
    return $?
}

check_for_remote_branch() {
    BRANCH="$1"
    git ls-remote --exit-code --heads origin "$BRANCH"
    return $?
}

cleanup_on_exit() {
    # Remove PR branch, if it exists
    echo "Swapping from temporary branch to: $HEAD_BRANCH"
    git checkout main > /dev/null 2>&1
    if (check_for_local_branch "$PR_BRANCH"); then
        echo "NOT removing temporary local branch during debugging: $PR_BRANCH"
        # git branch -d "$PR_BRANCH" > /dev/null 2>&1
    fi
    if [ -d "$DEVOPS_DIR" ]; then
        echo "Removing interim/temporary devops repository..."
        rm -Rf "$DEVOPS_DIR"
    fi
    if [ -f "$SHELL_SCRIPT" ]    ; then
        echo "NOT removing shell code during debugging"
        echo "Script path: $SHELL_SCRIPT"
        # rm "$SHELL_SCRIPT"

    fi
}
trap cleanup_on_exit EXIT

### Main script entry point

HEAD_BRANCH=$("$GIT_CMD" rev-parse --abbrev-ref HEAD)
REPO_DIR=$(git rev-parse --show-toplevel)
# Change to top-level of GIT repository
CURRENT_DIR=$(pwd)
if [ "$REPO_DIR" != "$CURRENT_DIR" ]; then
    echo "Changing directory to: $REPO_DIR"
    cd "$REPO_DIR" || change_dir_error
fi

# Directory used below MUST match code in bootstrap.yaml
DEVOPS_DIR=".devops"
echo "Cloning DevOps repository into: $DEVOPS_DIR"
git clone "$DEVOPS_REPO" "$DEVOPS_DIR"

# The section below extracts shell code from the bootstrap.yaml file
echo "Extracting shell code from bootstrap.yaml file..."
EXTRACT="false"
while read -r LINE; do
    if [ "$LINE" = "### SHELL CODE START ###" ]; then
        EXTRACT="true"
        SHELL_SCRIPT=$(mktemp -t script-XXXXXXXX.sh)
        touch "$SHELL_SCRIPT"
        chmod a+x "$SHELL_SCRIPT"
        echo "Creating shell script: $SHELL_SCRIPT"
        echo "#!/bin/sh" > "$SHELL_SCRIPT"
    fi
    if [ "$EXTRACT" = "true" ]; then
        echo "$LINE" >> "$SHELL_SCRIPT"
        if [ "$LINE" = "### SHELL CODE END ###" ]; then
            echo "Successfully extracted shell script from bootstrap.yaml"
            break
        fi
    fi
done < "$DEVOPS_DIR"/.github/workflows/bootstrap.yaml

echo "Running extracted shell script code"
# set +eu +o pipefail
# "$SHELL_SCRIPT"
cat "$SHELL_SCRIPT"
