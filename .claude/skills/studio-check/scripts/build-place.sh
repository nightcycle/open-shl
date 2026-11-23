#!/bin/sh
# builds one place of deploy.yml in a SNAPSHOT outside the repo, so the repo's own generated files
# (Generated/BUILD_CONFIG.luau, default.project.json, sourcemap.json) are never switched to another game, mode or flag
# while the owner's `rojo serve` + other agents read them. nothing is published, nothing in the repo is written.
#
# usage: sh build-place.sh <source> <snapshot dir> <out.rbxl> <universe> <place> [NAME=value ...]
#   <source>            a commit (HEAD, a hash, a branch): the tree of `git archive <source>`, nothing uncommitted
#                       or WORK: a mirror of the working tree, uncommitted edits included
#   <snapshot dir>      a scratch directory of your own OUTSIDE the repo, one per agent. a commit wipes + refills it,
#                       WORK mirrors into it (a second call is fast)
#   <universe> <place>  names from deploy.yml: `shl2 root`, `shl2 roleplay`, `shl2 private-server`, `shl3 root`,
#                       `shl3 roleplay`, `shl1 root`
#   NAME=value          build variables on top of the place's own: HARNESS_ENABLED=true, TESTS_ENABLED=true,
#                       MODE_SELECT_ENABLED=false, STORIES_ENABLED=false ..
# afterwards the snapshot holds that place's project json (snap.project.json) + BUILD_CONFIG, so the type check can be
# run inside it AS THAT GAME SEES THE CODE:
#   cd <snapshot dir> && rojo sourcemap snap.project.json --output sourcemap.json && luau-lsp analyze ...
# the repo is found from where this script sits, REPO=<path> says otherwise.
set -e
SOURCE="$1"
SNAP="$2"
OUT="$3"
UNIVERSE="$4"
PLACE="$5"
[ -n "$PLACE" ] || {
	echo "usage: sh build-place.sh <commit | WORK> <snapshot dir> <out.rbxl> <universe> <place> [NAME=value ...]" >&2
	exit 2
}
shift 5
: "${REPO:=$(cd "$(dirname "$0")" && git rev-parse --show-toplevel)}"
case "$(cd "$(dirname "$SNAP")" 2>/dev/null && pwd -W 2>/dev/null || dirname "$SNAP")/" in
"$(cd "$REPO" && pwd -W 2>/dev/null || echo "$REPO")"/*)
	echo "the snapshot must not be inside the repo" >&2
	exit 2
	;;
esac

# a folder git doesn't track (what wally installed, what the generators wrote) comes over as it lies in the repo
mirror() {
	[ -d "$REPO/$1" ] || return 0
	if command -v robocopy >/dev/null 2>&1; then
		STATUS=0
		MSYS_NO_PATHCONV=1 robocopy "$(cygpath -w "$REPO/$1")" "$(cygpath -w "$SNAP/$1")" /MIR /NFL /NDL /NJH /NJS /NP /R:2 /W:1 >/dev/null || STATUS=$?
		# robocopy: below 8 is a success
		[ "$STATUS" -lt 8 ] || {
			echo "robocopy failed on $1 ($STATUS)" >&2
			exit 1
		}
	else
		rm -rf "${SNAP:?}/$1"
		cp -R "$REPO/$1" "$SNAP/$1"
	fi
}

if [ "$SOURCE" = "WORK" ]; then
	mkdir -p "$SNAP"
	for DIR in src scripts lib data asset Packages DevPackages Generated; do
		mirror "$DIR"
	done
	for FILE in deploy.yml asphalt.toml pseudo-enum.toml rokit.toml selene.toml stylua.toml string-require.yml wally.toml wally.lock .luau-analyze.json .luaurc; do
		[ -f "$REPO/$FILE" ] && cp "$REPO/$FILE" "$SNAP/$FILE"
	done
else
	rm -rf "$SNAP"
	mkdir -p "$SNAP"
	(cd "$REPO" && git archive "$SOURCE") | tar -x -C "$SNAP"
	for DIR in Packages DevPackages; do
		mirror "$DIR"
	done
	# what `pseudo-enum build` + `asphalt sync studio` wrote: neither is run here, asphalt has printed its key before
	mkdir -p "$SNAP/Generated"
	for FILE in PseudoEnum Image Audio Animation; do
		cp "$REPO/Generated/$FILE.luau" "$SNAP/Generated/"
	done
	cp "$REPO/wally.lock" "$SNAP/" 2>/dev/null || true
fi

mkdir -p "$(dirname "$OUT")"
cd "$SNAP"
eval "$(UNIVERSE="$UNIVERSE" PLACE="$PLACE" lune run scripts/proj/env.lune.luau)"
for PAIR in "$@"; do
	export "$PAIR"
done
export PROJECT="snap.project.json"
lune run scripts/proj/config.lune.luau
lune run scripts/proj/build-config.lune.luau
rojo build "$PROJECT" -o "$OUT"
