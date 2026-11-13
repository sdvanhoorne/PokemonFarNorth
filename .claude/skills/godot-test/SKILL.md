---
name: godot-test
description: Run and write headless tests for this Godot project, and smoke-launch the game to catch script errors. Use after changing any GDScript, when verifying a bug fix, or when asked to test something.
---

# Testing in PokemonFarNorth

Godot 4.4 is installed at `/Applications/Godot.app/Contents/MacOS/Godot` (below: `GODOT`).

## Run the tests

```bash
GODOT --headless --path . res://tests/TestRunner.tscn                      # all tests
GODOT --headless --path . res://tests/TestRunner.tscn -- --filter=damage   # files whose name contains "damage"
```

- Exit code 0 means all passed, 1 means a failure. Output lines are `PASS file :: test` / `FAIL file :: test` plus failure details.
- **Also scan the output for `SCRIPT ERROR`.** A runtime error inside a test aborts that test method silently and it can still show as PASS. Treat any `SCRIPT ERROR` as a failure.
- After adding new `.gd` files, run `GODOT --headless --path . --import` once so Godot registers new `class_name`s.
- The runner is a scene (not `--script`) so autoloads like `Pokedex`, `MoveDatabase` and `TrainerDatabase` are available to tests.

## Write a test

Create `tests/test_<area>.gd`:

```gdscript
extends TestCase

func test_something_specific() -> void:
    var calc := DamageCalculation.new()
    check_approx(calc.get_type_effectiveness("fire", "grass"), 2.0, "fire -> grass")
    check_eq(some_int, 3, "label")
    check(condition, "message when false")
```

- One file per script under test; one `test_*` method per behavior. Each method gets a fresh `TestCase` instance.
- Name the test after the behavior, and for a bug fix reference the issue in a comment (`# Issue #7: ...`).
- Restore any global/static state you change (static vars, autoload fields, `PlayerInventory`, `GameState`).
- Build battle objects in code (`Pokemon`, `BattlePokemon`, `Move.new({...})`); don't load scenes unless the behavior needs the scene tree.
- **For bug fixes: the test must fail before the fix and pass after.** Confirm the failure first (or reason explicitly why it would fail on the old code if reverting is impractical).

## Smoke-launch the game

Catches parse errors and startup crashes in code the tests don't touch:

```bash
GODOT --path . --quit-after 300 2>&1 | grep -E "SCRIPT ERROR|ERROR|Parse" || echo "no errors"
```

This only reaches the title screen. It does **not** exercise the overworld or battles, so say so when reporting, and ask the user to play-test those paths if the change touches them.

## Limits

- `--check-only --script` fails in this project (autoload identifiers aren't known in that mode); use the runner instead.
- Tests can't drive input or animations; for UI/flow changes, describe what the user should play-test.
