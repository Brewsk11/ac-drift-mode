#!/bin/bash
set -ex

# Run autogeneration
./generate_models.sh

# Assemble directories for release/installation

VERSION=$(git describe --tags)
if [[ -z  "$VERSION" ]]; then
    VERSION=$(git rev-parse HEAD)
    VERSION=${VERSION:0:7}
fi

rm -rf output

mkdir -p output/assettocorsa/apps/lua
mkdir -p output/assettocorsa/lua
mkdir -p output/assettocorsa/extension/lua/new-modes
mkdir -p output/assettocorsa/extension/config/drift-mode

cp -r apps/*     output/assettocorsa/apps/lua
cp -r lua_libs/* output/assettocorsa/lua
cp -r modes/*    output/assettocorsa/extension/lua/new-modes
cp -r config/*   output/assettocorsa/extension/config/drift-mode

cp "res/logo white.png" output/assettocorsa/apps/lua/drift-mode/icon.png
cp "res/logo white tool.png" output/assettocorsa/apps/lua/drift-mode-editor/icon_tool.png
cp "res/logo white info.png" output/assettocorsa/apps/lua/drift-mode/icon_info.png
cp "res/logo white score.png" output/assettocorsa/apps/lua/drift-mode/icon_score.png
cp "res/logo white.png" "output/assettocorsa/extension/lua/new-modes/drift-mode/logo white.png"

cp ./INSTALL.md output/README.txt
cp ./uninstall_driftmode.bat output/

find ./output -name *.ini -exec sed -i "s/VERSION = XXX/VERSION = $VERSION/"  {} \;

echo "$VERSION" > ./output/VERSION.txt
