#!/bin/bash
set -ex

./assemble.sh

VERSION=$(git describe --tags)
if [[ -z  "$VERSION" ]]; then
    VERSION=$(git rev-parse HEAD)
    VERSION=${VERSION:0:7}
fi

echo "Packaging $VERSION"

cd output
rm -f ../packaged/ac-drift-mode-$VERSION.zip
zip ../packaged/ac-drift-mode-$VERSION.zip -r ./*
cd - 2>&1 > /dev/null