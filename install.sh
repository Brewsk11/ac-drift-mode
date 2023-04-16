#!/bin/bash

./assemble.sh

cp -R ./output/* "$(cat assetto_directory.txt)"
