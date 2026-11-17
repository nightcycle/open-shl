#!/bin/bash
# run by editor to set some useful variables / shortcuts in the bash terminal on open before usage

[ -f ~/.bashrc ] && source ~/.bashrc
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Export the project's .env values to commands launched from this terminal.
# Normalize Windows line endings and preserve the caller's allexport setting.
if [ -f "$PROJECT_ROOT/.env" ]; then
  if [[ $- == *a* ]]; then
    source <(sed 's/\r$//' "$PROJECT_ROOT/.env")
  else
    set -a
    source <(sed 's/\r$//' "$PROJECT_ROOT/.env")
    set +a
  fi
fi

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
