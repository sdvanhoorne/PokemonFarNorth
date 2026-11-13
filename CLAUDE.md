# PokemonFarNorth

Gen 3 inspired Pokemon remake in Godot 4.4 (GDScript), 240x160 viewport, grid movement.

## Layout
- `scripts/` by domain: battle, moves, pokemon, player, npc, world, globals (autoloads listed in project.godot)
- `scenes/` mirrors scripts: battle, ui, world (routes, caves, interactables), npc, player
- `data/` JSON-style game data: pokedex, pokemon, moves, items, encounters, npc, types
- `assets/` sprites, tiles, themes

## Conventions
- Static typing in GDScript; Godot 4 syntax only.
- Keep logic out of UI scripts; battle engine emits events, UI renders them.
- Prefer data-driven content in `data/` over hard-coding.
- Battle rules are Gen 3 except the physical/special split, which is per move (Gen 4+) via each move's `category`.
- Don't hand-edit .godot/ or .uid files.
- Tests: `tests/test_*.gd` (extend `TestCase`), run headless with `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/TestRunner.tscn`. See the `godot-test` skill.
- Battle engine redesign notes (draft, under review): `docs/battle-engine-v2.md`.

## Subagents (.claude/agents)
battle-mechanics, pokemon-data, map-designer, ui-gba-style, gdscript-reviewer
