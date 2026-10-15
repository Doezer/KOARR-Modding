# Development

The release source is `mods/all_quest_markers_native.json`. Build and check its
package with Python 3 (no extra Python packages):

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py
```

To check signatures against your own legally installed executable, without
modifying it:

```sh
python3 tools/verify_executable.py /path/to/koa.exe
```

The verifier accepts only the exact analyzed SHA-256. Passing it checks the file
and signatures; it does not establish every aspect of in-game compatibility.

Historical Lua prototype tests can also run with `./tools/setup_lua.sh` followed by
`./tools/check.sh`. They test the earlier core/helpers and do not validate the
native mod in the game. See [native patch details](native-patches.md) and
[historical research](runtime-findings.md).

