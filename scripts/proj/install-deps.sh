#!/bin/sh
set -e

# I prefer using env variables over args as it allows for cleaner reuse in workflows
: "${PROJECT:=default.project.json}"
: "${SOURCEMAP:=sourcemap.json}"

echo "installing rokit tooling"
rokit install

echo "installing wally packages"
wally install
if [ ! -f "$SOURCEMAP" ]; then
	sh "scripts/sourcemap.sh"
fi
set +e
echo "extracting wally package types"
wally-package-types "Packages" --sourcemap "$SOURCEMAP" >/dev/null 2>&1
wally-package-types "DevPackages" --sourcemap "$SOURCEMAP" >/dev/null 2>&1
set -e
