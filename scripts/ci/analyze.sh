#!/bin/sh
# the slow test, every type under src is held against the rest of the code + the engine
set -e

# I prefer using env variables over args as it allows for cleaner reuse in workflows
: "${PROJECT:=default.project.json}"
: "${SOURCEMAP:=sourcemap.json}"
# a file to check against in place of the pinned one, it's taken as it is
: "${DEFINITIONS:=}"
# the scripts below read both of these as well
export PROJECT SOURCEMAP

# luau-lsp doesn't come with the types of the engine + they aren't committed. the file under the tag of the version in
# rokit.toml is older than some of the API used here, this later commit of its repo is one that version still loads
DEFINITIONS_COMMIT="bd4a2ab3a78df82569fb7c2c8fa63d222b4346e0"
DEFINITIONS_URL="https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$DEFINITIONS_COMMIT/scripts/globalTypes.d.luau"
DEFINITIONS_SHA256="586ca7282861c26003b657643a7d35ac24629aaa09c65e1e2276279f30d7c79d"

echo "generating project + code"
lune run scripts/proj/config.lune.luau
sh scripts/proj/code-gen.sh
sh scripts/sourcemap.sh

if [ -z "$DEFINITIONS" ]; then
	# a runner has a temp directory of its own
	TEMP_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
	# luau-lsp isn't an msys program, it has to be handed the path windows knows the directory by
	if command -v cygpath >/dev/null 2>&1; then
		TEMP_DIR="$(cygpath -m "$TEMP_DIR")"
	fi
	DEFINITIONS="$TEMP_DIR/globalTypes-$DEFINITIONS_COMMIT.d.luau"

	# kept from one run to the next, the file behind a commit doesn't change
	if [ ! -f "$DEFINITIONS" ]; then
		echo "downloading roblox definitions to \"$DEFINITIONS\""
		curl --fail --silent --show-error --location --retry 3 --output "$DEFINITIONS.part" "$DEFINITIONS_URL"
		mv "$DEFINITIONS.part" "$DEFINITIONS"
	fi

	SHA256="$(sha256sum <"$DEFINITIONS" | cut -d " " -f 1)"
	if [ "$SHA256" != "$DEFINITIONS_SHA256" ]; then
		echo "\"$DEFINITIONS\" isn't the pinned definitions file, its sha256 is $SHA256 rather than $DEFINITIONS_SHA256"
		# the next run downloads it again
		rm -f "$DEFINITIONS"
		exit 1
	fi
elif [ ! -f "$DEFINITIONS" ]; then
	echo "no definitions file at \"$DEFINITIONS\""
	exit 1
fi

echo "analyzing src against \"$DEFINITIONS\""
luau-lsp analyze \
	--sourcemap "$SOURCEMAP" \
	--definitions "@roblox=$DEFINITIONS" \
	--settings .luau-analyze.json \
	--ignore "Packages/**" \
	--ignore "DevPackages/**" \
	src
