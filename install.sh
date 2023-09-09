#!/bin/bash
set -ex

./assemble.sh

cp -R ./output/assettocorsa/* "$(cat .assetto_directory)"
cp -R ./output/uninstall_driftmode.bat "$(cat .assetto_directory)"
