#!/usr/bin/env bash

### Script to bootstrap the OS-Climate DevOps environment ###

set -eu -o pipefail
# set -xv

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
        rm -Rf "$DEVOPS_DIR"
        echo "Removed temporary devops repository clone"
    fi
    if [ -f "$SHELL_SCRIPT" ]    ; then
        echo "NOT removing shell code during debugging"
        # rm "$SHELL_SCRIPT"

    fi
}
trap cleanup_on_exit EXIT

### Main script entry point

# Get organisation and repository name
# git config --get remote.origin.url
# git@github.com:ModeSevenIndustrialSolutions/test-bootstrap.git
URL=$(git config --get remote.origin.url)

# Take the above and store it converted as ORG_AND_REPO
# e.g. ModeSevenIndustrialSolutions/test-bootstrap
ORG_AND_REPO=${URL/%.git}
ORG_AND_REPO=${ORG_AND_REPO//:/ }
ORG_AND_REPO=$(echo "$ORG_AND_REPO" | awk '{ print $2 }')
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
printf "Cloning DevOps repository into: %s" $DEVOPS_DIR
if (git clone "$DEVOPS_REPO" "$DEVOPS_DIR" > /dev/null 2>&1); then
    echo " [successful]"
else
    echo " [failed]"; exit 1
fi

# The section below extracts shell code from the bootstrap.yaml file
echo "Extracting shell code from bootstrap.yaml file"
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
            echo "Script extraction complete"
            break
        fi
    fi
done < "$DEVOPS_DIR"/.github/workflows/bootstrap.yaml

echo "Running extracted shell script code"
# "$SHELL_SCRIPT"
