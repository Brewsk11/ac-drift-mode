#!/bin/bash

# Assemble directories for release/installation

rm -rf output

mkdir -p output/apps/lua/drift-mode
mkdir -p output/lua/drift-mode
mkdir -p output/extension/lua/new-modes

cp app/* output/apps/lua/drift-mode
cp lua_libs/* output/lua/drift-mode
cp -r modes/* output/extension/lua/new-modes
