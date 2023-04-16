#!/bin/bash

# Assemble directories for release/installation

mkdir -p output/apps/lua/drift-mode
mkdir -p output/lua/drift-mode
mkdir -p output/extension/lua/new-modes/drift-mode

cp app/* output/apps/lua/drift-mode
cp lua_libs/* output/lua/drift-mode
cp mode/* output/extension/lua/new-modes/drift-mode
