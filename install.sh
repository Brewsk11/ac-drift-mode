#!/bin/bash
set -ex

./assemble.sh

cp -R ./output/assettocorsa/* "$(cat assetto_directory.txt)"
