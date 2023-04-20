#!/bin/bash

# Assemble directories for release/installation

VERSION=$(git describe --tags)
if [[ -z  "$VERSION" ]]; then
    VERSION=$(git rev-parse HEAD)
    VERSION=${VERSION:0:7}
fi

rm -rf output

mkdir -p output/ac_gamedir/apps/lua/drift-mode
mkdir -p output/ac_gamedir/lua/drift-mode
mkdir -p output/ac_gamedir/extension/lua/new-modes
mkdir -p output/ac_usercfg/cfg/extension/drift-mode

cp app/*      output/ac_gamedir/apps/lua/drift-mode
cp lua_libs/* output/ac_gamedir/lua/drift-mode
cp -r modes/* output/ac_gamedir/extension/lua/new-modes
cp config/*   output/ac_usercfg/cfg/extension/drift-mode

cp ./INSTALL.md output/

find ./output -name *.ini -exec sed -i "s/VERSION = XXX/VERSION = $VERSION/"  {} \;
