#!/bin/bash
# run by editor to set some useful variables / shortcuts in the bash terminal on open before usage

[ -f ~/.bashrc ] && source ~/.bashrc
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sourcemap() {
  sh scripts/sourcemap.sh "$@"
}

build() {
  sh scripts/build.sh "$@"
}

sync() {
  sh scripts/sync.sh "$@"
}

install-deps() {
  sh scripts/install-deps.sh "$@"
}

unpack() {
  lune run scripts/util/unpack-rbxm.lune.luau "$@"
}
# Path shortcuts
export UTIL="$PROJECT_ROOT/scripts/util"
export ANALYSIS="$PROJECT_ROOT/scripts/unit-testing/analysis"