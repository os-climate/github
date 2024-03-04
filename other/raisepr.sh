#!/usr/bin/env bash

### Script to bulk raise a PR in multiple repositories ###

set -o pipefail
# set -x

### Variables ###

PARALLEL_THREADS="1"
echo "Parallel threads: $PARALLEL_THREADS"

### Checks ###

GIT_CLI=$(which git)
if [ ! -x "$GIT_CLI" ]; then
    echo "GIT was not found in your PATH"; exit 1
fi
export GIT_CLI

GITHUB_CLI=$(which gh)
if [ ! -x "$GITHUB_CLI" ]; then
    echo "The GitHub CLI was not found in your PATH"; exit 1
fi
export GITHUB_CLI

### Functions ###

auth_check() {
    if ! (gh auth status); then
        echo "You are not logged into GitHub"
        echo "Use the command: gh auth login"; exit 1
    fi
}

change_dir_error() {
    echo "Could not change directory"
    exit 1
}

### Operations ###

auth_check

# See if the repository has a pre-commit configuration file
# If NOT, copy the template file in place to prevent errors

find -- * -depth 0 -type d -print0 | while read -r -d $'\0' REPO; do
    if [ ! -f "$REPO"/.pre-commit-config.yaml ]; then
        echo "No pre-commit config: $REPO"
        cp .pre-commit-config.yaml "$REPO"

        ### Values for GIT operations
        BRANCH="implement-minimal-precommit"
        TITLE="Implement minimal pre-commit configuration for pre-commit.ci"
        BODY="This will satisfy pre-commit.ci and prevent merges from blocking"

        ### Raise a PR with upstream/main
        cd "$REPO" || change_dir_error
        "$GIT_CLI" pull
        "$GIT_CLI" checkout -b "$BRANCH"
        "$GIT_CLI" add .pre-commit-config.yaml
        "$GIT_CLI" commit -as -S -m "Chore: $TITLE" --no-verify
        "$GIT_CLI" push
        PR_URL=$("$GITHUB_CLI" pr create --title "$TITLE" --body "$BODY")
        PR_NUMBER=$(basename "$PR_URL")
        echo "Pull request #$PR_NUMBER URL: $PR_URL"
        echo "Sleeping..."
        sleep 60
        "$GITHUB_CLI" pr merge "$URL" --delete-branch --merge
        "$GIT_CLI" push origin --delete "$BRANCH" > /dev/null 2>&1 &
        "$GIT_CLI" push upstream --delete "$BRANCH" > /dev/null 2>&1 &
        # Change back to parent directory
        cd .. || change_dir_error

        ### Optionally remove branches (if not handled automatically by repo settings)
        # if (git ls-remote --heads origin refs/heads/"$BRANCH"); then
        #      echo "Attempting deletion of branch: origin/$BRANCH"
        #      git push origin --delete "$BRANCH"
        # fi
        # if (git ls-remote --heads upstream refs/heads/"$BRANCH"); then
        #   echo "Attempting deletion of branch: upstream/$BRANCH"
        #      git push upstream --delete "$BRANCH"
        # fi
    fi
done
echo "Script completed"; exit 0
