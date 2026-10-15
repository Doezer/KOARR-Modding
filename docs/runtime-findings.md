> Historical investigation log. The working release is now the combined
> [three-patch manifest](../mods/all_quest_markers_native.json); follow the
> [current README](../README.md). Earlier experimental file paths below have
> been superseded.

# Local analysis of private runtime exports

The user supplied a complete console export containing 55 Havok Script functions
(45,563 bytes). Every hex block was decoded and matched its declared byte count.
Private compiled scripts and their disassemblies remain outside this repository.
No raw scripts, extracted constants, code listings or game assets are redistributed.

The format is a Lua-signature Havok variant with format byte 0x08, big-endian
32-bit fields, a type-name map, and the legacy expanded instruction set. Parsing
was based on the public Kender2 research and cross-checking instruction fields
against DSLuaDecompiler's Havok decoder. The current DSLuaDecompiler targets a
newer Havok format, so it was not used to claim successful full decompilation.
A local read-only parser recovered top-level function parameters, code and
constants. Control-flow conclusions were limited to directly checked instructions.

The journal's update routine enumerates active IDs with zero-based indices and
includes a quest in its active grouping only when `get_stage(id) > 0`. Quest types
that are nil or empty default to Main. This explains why the native active count
alone is insufficient. A new project-original quest_reader module implements
that read-only enumeration while preserving opaque native IDs. It does not yet
retrieve destinations, apply reveal rules or render markers. Synthetic tests
verify stage filtering and ID preservation; game execution of this reader is unrun.

The supplied minimap routines manage the corner minimap's initialization,
visibility, radius, rotation and region changes. Neither target-list query name
occurs anywhere in the 55 supplied binary exports. This establishes only that
those exports do not contain the relevant names; it does not establish that no
Lua caller exists. Aliases, cached native calls or functions outside the supplied
modules remain possible.

The next source search scans loaded modules for compiled functions that reference
`get_target_indexes` or `get_target_types`, rather than guessing another module
name. The standalone find_map_code helper also searches icon API references.
It calls only standard string.dump on function objects; it never executes the
candidate functions or starts game queries. Limits and examined/matched counts
are reported, so a limited or empty search is not described as proof of absence.

No new package or release was pushed after the user's request for direct edits.

## Supplied GOG executable

Static analysis of the subsequently supplied executable located a candidate
native solution independent of the Lua adapter. Two world-map-specific branches
skip untracked quest targets during initial population and later updates. The
experimental manifest and its install/test instructions are in `experimental/`.
Offline signature, relocation and instruction-boundary checks passed. In-game
behavior is unverified. No binary or full disassembly is included.

The user subsequently confirmed that the initial native patch exposes local
untracked targets, but distant markers appear only when their quests are tracked.
A further renderer branch applies a region/path eligibility predicate specifically
to inactive objective icons. A separate experimental world-scope manifest bypasses
that predicate only on the world map. Exact-build signature/relocation checks and
50 isolated x86 emulation comparisons passed. Its actual game behavior remains
unverified; the first patch's reported success is partial, not global coverage.

The user confirmed that the combined three-patch manifest works in-game. This
is a positive report for the tested save/map situation; objective completion,
all DLC, interiors and every visibility case have not been exhaustively tested.
The patches have separate roles: initial population, later target updates, and
the renderer's inactive-objective eligibility check. No controlled removal test
has established a smaller equivalent set.

## Larger-region variant feasibility

The executable contains a named enumeration for Dalentarth (0), Erathell (1),
Erathell Snow (2), Detyre (3), Alabastra (4) and Klurikon (5), followed by generic
Zone entries. Native code maps region keys to classification bytes, separately
from UI world-map region/type metadata. These provide candidate building blocks
for a larger-area filter, but the mapping of actual objective destinations,
interiors and DLC to user-facing larger areas is not yet validated. The existing
renderer-scope patch bypasses a predicate; it is not a configurable comparison
against these named areas. A regional variant requires a further comparison and
runtime checks, not removal of one of the existing patches. Player location versus
map-view selection is a separate behavior choice requested from the user.
