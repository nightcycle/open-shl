#!/bin/sh
set -e
# I prefer using env variables over args as it allows for cleaner reuse in workflows
: "${PROJECT:=default.project.json}"
: "${SOURCEMAP:=sourcemap.json}"
: "${UPLOAD_ASSETS:=false}"

echo "uploading assets"

if [ "$UPLOAD_ASSETS" = "true" ]; then
	asphalt sync cloud
elif [ "$UPLOAD_ASSETS" = "false" ]; then
	asphalt sync studio
else
	echo "unsupported UPLOAD_ASSETS value \"$UPLOAD_ASSETS\""
	exit 1
fi