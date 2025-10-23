#!/bin/bash

ACDIR_FILE=".assetto_directory"

if [ ! -f ${ACDIR_FILE} ]; then
    echo "Create ${ACDIR_FILE} file with a path to your Assetto Corsa installation."
    exit 1
fi

if [ ! -f "$(cat ${ACDIR_FILE})/acs.exe" ]; then
    echo "${ACDIR_FILE} contains invalid AC path (acs.exe not found)"
    exit 2
fi

set -ex

./assemble.sh

cp -R ./output/assettocorsa/* "$(cat ${ACDIR_FILE})"
