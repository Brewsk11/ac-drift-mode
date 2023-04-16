#!/bin/bash

# Assemble directories for release/installation

mkdir -p output/assettocorsa/apps/lua/drift-mode
mkdir -p output/assettocorsa/lua/drift-mode
mkdir -p output/assettocorsa/extension/lua/new-modes/drift-mode

cp app/* output/assettocorsa/apps/lua/drift-mode
cp lua_libs/* output/assettocorsa/lua/drift-mode
cp mode/* output/assettocorsa/extension/lua/new-modes/drift-mode

