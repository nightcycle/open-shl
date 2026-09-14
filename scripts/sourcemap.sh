#!/bin/sh
# provides important metadata to many tools regarding what instances / scripts exist and where
set -e
: "${PROJECT:=default.project.json}"
: "${SOURCEMAP:=sourcemap.json}"

echo "building sourcemap for \"${PROJECT}\" at $SOURCEMAP"
rojo sourcemap "$PROJECT" --output="$SOURCEMAP"