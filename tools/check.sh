#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cache=${AQM_TOOLS_DIR:-/workspace/.aqm-tools}
export AQM_LUA="$cache/lua-5.1.5/src/lua"
compiler="$cache/lua-5.1.5/src/luac"
if [ ! -x "$AQM_LUA" ] || [ ! -x "$compiler" ]; then
  echo 'Run ./tools/setup_lua.sh first' >&2
  exit 1
fi
while IFS= read -r -d '' source; do
  "$compiler" -p "$source"
done < <(find mods tests -name '*.lua' -print0)
"$AQM_LUA" tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py' -v
