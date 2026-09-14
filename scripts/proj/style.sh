#!/bin/sh
set -e

# I prefer using env variables over args as it allows for cleaner reuse in workflows
: "${PROJECT:=default.project.json}"
: "${SOURCEMAP:=sourcemap.json}"

echo "styling code"
stylua src

