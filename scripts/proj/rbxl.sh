#!/bin/sh
set -e
# builds project into an rbxl

# I prefer using env variables over args as it allows for cleaner reuse in workflows
: "${PROJECT:=default.project.json}"
: "${RBXL:=project.rbxl}"

echo "building rbxl"
rojo build "$PROJECT" -o "$RBXL"
