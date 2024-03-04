#!/bin/sh

myfunction() {
    echo "test"
}

# shellcheck disable=SC3045
export -f myfunction

parallel -j3 ::: myfunction
