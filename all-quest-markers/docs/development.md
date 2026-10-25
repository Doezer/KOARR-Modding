# Development

Run the commands below from the repository’s `all-quest-markers/` folder.

The release source is `mods/all_quest_markers_native.json`. Build and check its
package with Python 3 (no extra Python packages):

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/package.py --output build
```

To check signatures against your own legally installed executable, without
modifying it:

```sh
python3 tools/verify_executable.py /path/to/koa.exe
```

The verifier accepts only the exact analyzed SHA-256. Passing it checks the file
and signatures; it does not establish every aspect of in-game compatibility.

The package tests check the install layout, manifest structure, reproducibility
and checksum. They do not execute the game. See the [native patch details](native-patches.md)
for implementation and validation evidence.

The `build/` directory is ignored by Git. Published ZIPs in `dist/` are retained
for the existing download links; update them only as part of a new release.
