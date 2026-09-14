#!/bin/sh
set -e
lune run scripts/proj/config.lune.luau
sh scripts/proj/code-gen.sh
sh scripts/proj/install-deps.sh
sh scripts/proj/sync.sh
sh scripts/proj/style.sh
sh scripts/sourcemap.sh
sh scripts/proj/rbxl.sh