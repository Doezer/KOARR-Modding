#!/usr/bin/env bash
set -euo pipefail
# Use a workspace cache; never install into system directories.
cache=${AQM_TOOLS_DIR:-/workspace/.aqm-tools}
mkdir -p "$cache"
cd "$cache"
if [ ! -x lua-5.1.5/src/lua ] || [ ! -x lua-5.1.5/src/luac ]; then
  curl --fail --location --retry 2 https://www.lua.org/ftp/lua-5.1.5.tar.gz -o lua-5.1.5.tar.gz
  echo '2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333  lua-5.1.5.tar.gz' | sha256sum --check --strict
  tar -xzf lua-5.1.5.tar.gz
  make -C lua-5.1.5 generic -j2
fi
"$cache/lua-5.1.5/src/lua" -v
