#!/bin/bash
set -ex

# Assemble directories for release/installation

VERSION=$(git describe --tags)
if [[ -z  "$VERSION" ]]; then
    VERSION=$(git rev-parse HEAD)
    VERSION=${VERSION:0:7}
fi

rm -rf output

mkdir -p output/ac_gamedir/apps/lua
mkdir -p output/ac_gamedir/lua
mkdir -p output/ac_gamedir/extension/lua/new-modes
mkdir -p output/ac_usercfg/cfg/extension

cp -r apps/*     output/ac_gamedir/apps/lua
cp -r lua_libs/* output/ac_gamedir/lua
cp -r modes/*    output/ac_gamedir/extension/lua/new-modes
cp -r config/*   output/ac_usercfg/cfg/extension

cp ./INSTALL.md output/

find ./output -name *.ini -exec sed -i "s/VERSION = XXX/VERSION = $VERSION/"  {} \;
