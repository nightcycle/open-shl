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
elif [ "$UPLOAD_ASSETS" = "locked" ]; then
	# what a pipeline builds with: the ids of whatever is uploaded already, an asset that isn't fails the sync
	asphalt sync cloud --dry-run
else
	echo "unsupported UPLOAD_ASSETS value \"$UPLOAD_ASSETS\""
	exit 1
fi