#!/bin/bash
set -ex


# Run model autogeneration
#   Run only if directory structure changed (cached tree hash)

function hashModels { find ${MODELS_PATH} | md5sum; }

MODELS_PATH="source/common/drift-mode/models"
MODELS_GEN_CACHE=".generate_models.cache"

if [[ ! -f ${MODELS_GEN_CACHE} || "$(hashModels)" != "$(cat ${MODELS_GEN_CACHE})" ]]; then
    ./scripts/generate_models_tree.py "${MODELS_PATH}"
    ./scripts/generate_models_reflection.py "${MODELS_PATH}"
    hashModels > ${MODELS_GEN_CACHE}
fi


# Get version as a tag, or latest tag + number of commits since

VERSION=$(git describe --tags)
if [[ -z  "$VERSION" ]]; then
    VERSION=$(git rev-parse HEAD)
    VERSION=${VERSION:0:7}
fi


# Purge the output dir

rm -rf output


# Populate output directories

mkdir -p               output/assettocorsa/apps/lua/drift-mode
cp -r source/apps/*    output/assettocorsa/apps/lua/drift-mode

# The common directory is adjusted for VSCode to recognize the paths nicely during development.
mkdir -p               output/assettocorsa/lua
cp -r source/common/*  output/assettocorsa/lua

mkdir -p               output/assettocorsa/extension/lua/new-modes/drift-mode
cp -r source/mode/*    output/assettocorsa/extension/lua/new-modes/drift-mode

mkdir -p               output/assettocorsa/extension/config/drift-mode
cp -r source/presets/* output/assettocorsa/extension/config/drift-mode

mkdir -p               output/assettocorsa/content/gui/drift-mode
cp -r resources/*.png  output/assettocorsa/content/gui/drift-mode


# Copy apps logos

cp "resources/logo_white.png"       output/assettocorsa/apps/lua/drift-mode/icon.png
cp "resources/logo_white_tool.png"  output/assettocorsa/apps/lua/drift-mode/icon_tool.png
cp "resources/logo_white_info.png"  output/assettocorsa/apps/lua/drift-mode/icon_info.png
cp "resources/logo_white_score.png" output/assettocorsa/apps/lua/drift-mode/icon_score.png
cp "resources/logo_white_map.png"   output/assettocorsa/apps/lua/drift-mode/icon_map.png


# Copy supplemental files

cp ./INSTALL.md output/README.txt
cp source/misc/uninstall_driftmode.bat output/assettocorsa/uninstall_driftmode.bat


# Put a version in the output

find ./output -name *.ini -exec sed -i "s/VERSION = XXX/VERSION = $VERSION/"  {} \;
echo "$VERSION" > ./output/VERSION.txt
