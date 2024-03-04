#!/usr/bin/env bash

### Script to bulk refresh a directory containing repositories ###

set -o pipefail
set -xv

### Variables ###

PARALLEL_THREADS="8"
echo "Parallel threads: $PARALLEL_THREADS"

### Checks ###

GIT_CLI=$(which git)
export GIT_CLI
if [ ! -x "$GIT_CLI" ]; then
    echo "GIT was not found in your PATH"; exit 1
fi

if [ $# -ne 1 ] || { [ ! "$1" = "clone" ] && [ ! "$1" = "fork" ]; } ; then
    echo "Usage: $0    [ clone | fork ]"; exit 1
else
    OPERATION="$1"
fi

### Functions ###

check_is_repo() {
    CURRENT_DIR=$(basename "$PWD")
    # Check current directory is a GIT repository
    "$GIT_CLI" status > /dev/null 2>&1
    if [ $? -eq 128 ]; then
        echo "Skipping folder NOT a git repository: $CURRENT_DIR"
        return 1
    else
        echo "Processing: $CURRENT_DIR -> \c"
        # Figure out which of the two options is the primary branch name
        GIT_MAIN=$("$GIT_CLI" branch -l main \
            master --format '%(refname:short)')
        export GIT_MAIN
        return 0
    fi
}

main_or_master() {
    # Only checkout main/master if not already on that branch
    if ! ("$GIT_CLI" rev-parse --abbrev-ref HEAD \
    | grep -E "main|master" > /dev/null 2>&1); then
        # Need to swap branch in this repository
        if ("$GIT_CLI" checkout "$GIT_MAIN"); then
            echo "$GIT_MAIN -> \c"
            return 0
        else
            echo "Error checking out $GIT_MAIN."
            return 1
        fi
    else
        # Already on the appropriate branch
        echo "$GIT_MAIN -> \c"
        return 0
    fi
}

update_fork() {
    echo "resetting -> \c"
    if ("$GIT_CLI" fetch upstream > /dev/null 2>&1; \
        "$GIT_CLI" reset --hard upstream/"$GIT_MAIN" > /dev/null 2>&1; \
        "$GIT_CLI" push origin "$GIT_MAIN" --force > /dev/null 2>&1); then
        echo "Done."
        return 0
    else
        echo "Error."
        return 1
    fi
}

update_clone() {
    echo "updating -> \c"
    if ("$GIT_CLI" pull > /dev/null 2>&1;); then
        echo "Done."
        return 0
    else
        echo "Error."
        return 1
    fi
}

change_dir_error() {
    echo "Could not change directory"
    exit 1
}

refresh_repo() {
    # Change into the target directory
    cd "$1" || change_dir_error
    # Check current directory is a GIT repository
    if check_is_repo; then
        if (main_or_master); then
            # Update origin against upstream
            if [ "$OPERATION" = "fork" ]; then
                update_fork
            elif [ "$OPERATION" = "clone" ]; then
                update_clone
            fi
        fi
    fi
    # Change back to parent directory
    cd .. || change_dir_error
}

# Make functions available to GNU parallel
# shellcheck disable=SC3045
export -f refresh_repo update_fork update_clone \
    main_or_master check_is_repo change_dir_error

### Operations ###

CURRENT_DIR=$(basename "$PWD")
echo "Processing all GIT repositories in: $CURRENT_DIR"

# parallel --record-env
# echo "hazard" | parallel --env _ --j 1 refresh_repo :::

# Update all local repositories from origin
# find * -depth 0 -type d | parallel --env _ refresh_repo :::
for FOLDER in $(find * -depth 0 -type d); do
    refresh_repo "$FOLDER"
    #parallel --env _ refresh_repo :::
done
echo "Script completed"; exit 0