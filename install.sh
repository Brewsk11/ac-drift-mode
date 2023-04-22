#!/bin/bash
set -ex

./assemble.sh

cp -R ./output/ac_gamedir/* "$(cat assetto_directory.txt)"
