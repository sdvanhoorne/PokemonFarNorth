# Battle Engine v2: Design Notes

Status: **draft for review.** Nothing below is logged as GitHub work yet, except the bugs listed in the next section. Once the design is agreed, it gets split into issues (see [Proposed issue breakdown](#proposed-issue-breakdown)).

Goal: a battle engine where new mechanics (weather, abilities, held items, moves like Leech Seed or Substitute) are added as **small self-contained pieces** rather than new `if` branches inside the engine.

---

## Already logged bugs (fix first)

These are defects in the current code, independent of the redesign:

| Issue | Summary |
|---|---|
| #2 | `BattlePokemon.Stat` and `PokemonStat.Stat` enums misaligned; evasion stages crash |
| #3 | STAB wrong: dual types always get it, single types never do |
| #4 | `BattleManager.return_to_world()` doesn't exist; most battle endings error |
| #5 | `BattlePokemon` accessed as `Pokemon` (`base_data`, `move_names`); `has_usable_player_pokemon()` missing |
| #6 | Status moves broken (`Move.status` missing, event payload mismatch, enum vs strings) |
| #7 | Type chart re-read from disk on every damage calculation |
| #8 | Accuracy, priority, PP and secondary effects not implemented |

---

## What the current design gets right

- **`BattleEngine` is plain logic** (`RefCounted`, no nodes) and **`BattleController` only plays back events.** Keep this split; everything below builds on it.
- **`BattleEvent` list per turn.** The engine decides what happened, and the UI decides how to show it. This also makes replays, tests and AI lookahead possible later.
- **`BattlePokemon` wraps `Pokemon`.** That's the right place for battle-only state.

## Current structural problems

1. **The controller changes battle state.** `BATTLER_SENT_IN` playback sets `session.active_player_index`, which the engine already did. Rule: *only the engine changes battle state*; the controller only reads it.
2. **Running away bypasses the engine.** It can't fail, doesn't use a turn, and ignores `can_run`.
3. **Moves branch on `category`** (`"physical"`, `"status"`, `"stat_change"`) and assume one effect per move. Each unusual move would need its own branch.
4. **There's nowhere to store temporary battle state:** confusion, substitute HP, seeded, toxic counter, last move used, flinch, screens, weather.
5. **Strings everywhere** (types, categories, statuses, targets) with mixed casing; this caused #3 and #6.
6. **The global `randf()`** means battles can't be seeded, so they can't be tested or reproduced.
7. **`BattleStateMachine` is unused.** Either drive the controller with it or delete it.

---

## Core ideas

### 1. Layers of state: where each piece of data lives

The question for any piece of data is: *how long does it last, and who does it belong to?*

```
Pokemon         persistent. Survives the battle and is saved.
                HP, status (burn/poison/…), PP, XP, ability, held item

BattlePokemon   volatile. Exists only while this Pokémon is in the battle; most of it resets on switch-out.
                stat_stages, volatiles {}, last_move, turns_active, substitute_hp

SideState       per side (player / enemy). Survives switching.
                reflect(turns), light_screen(turns), spikes(layers), tailwind(turns)

FieldState      whole battlefield.
                weather + turns_left, terrain, trick_room

BattleSession   owns all of the above + the RNG + turn number + result
```

Examples:
- **Burn** stays after you switch out, so it's on `Pokemon`.
- **Confusion** is cured by switching, so it's a volatile on `BattlePokemon`.
- **Leech Seed** is also cured by switching, so it's a volatile on the *seeded* Pokémon. It remembers which *side* planted it, because the heal goes to whoever is active on that side.
- **Reflect** protects whichever Pokémon is out, so it's on `SideState`.
- **Rain** affects everyone, so it's on `FieldState`.

### 2. A fixed turn pipeline

Today `resolve_turn` sorts two actions and resolves them. v2 makes every step of a turn explicit, so each mechanic knows *where* it plugs in:

```
1. Collect actions (player + AI)
2. Order:     switches/items/run first → move priority → effective speed → seeded RNG tie-break
3. For each action:
     a. before-move checks  sleep, freeze, paralysis (25% fail), flinch, confusion
     b. spend PP
     c. accuracy check      accuracy × (accuracy/evasion stages)
     d. try-hit checks      type immunity, Protect, Levitate vs Ground, Substitute
     e. damage              formula → modifier chain (see #4)
     f. secondary effects   Ember's 10% burn, stat drops, recoil, drain
     g. after-move          faint checks
4. End of turn (fixed order):
     weather damage/countdown → Leech Seed → poison/burn → screens count down
5. Faint replacements (forced switches)
```

Each step is a short function. The order matters and is defined in one place, so "does Leech Seed happen before or after burn?" has a single answer.

### 3. `BattleEffect` hooks (the main idea)

Abilities, items, weather, volatiles and side conditions are all "things that change the rules." Instead of the engine checking for each one by name, each one is a small object that **overrides only the hooks it cares about**:

```gdscript
class_name BattleEffect extends RefCounted

# Each hook gets a context object (ctx) with session, user, target, move, rng, events.
func on_switch_in(ctx) -> void: pass                      # Intimidate, Spikes
func on_before_move(ctx) -> bool: return true             # false = move fails (paralysis, sleep)
func on_try_hit(ctx) -> bool: return true                 # false = blocked (Protect, Levitate)
func modify_damage(ctx, dmg: float) -> float: return dmg  # weather, Blaze, Reflect, burn
func modify_speed(ctx, spd: float) -> float: return spd   # paralysis, Swift Swim
func modify_accuracy(ctx, acc: float) -> float: return acc
func on_end_of_turn(ctx) -> void: pass                    # Leech Seed, burn, weather countdown
func on_switch_out(ctx) -> void: pass                     # Natural Cure, clear volatiles
```

At each pipeline step the engine **collects every active effect**:

```
field (weather) → each side's conditions → each active Pokémon's ability, item, status, volatiles
```

Then it calls the matching hook on each one. The engine never mentions "Rain" or "Intimidate" by name.

#### Worked examples

**Rain (field effect)**
```gdscript
class_name RainEffect extends BattleEffect
var turns_left := 5
func modify_damage(ctx, dmg):
    if ctx.move.type == Type.WATER: return dmg * 1.5
    if ctx.move.type == Type.FIRE:  return dmg * 0.5
    return dmg
func on_end_of_turn(ctx):
    turns_left -= 1
    if turns_left == 0:
        ctx.session.field.weather = null
        ctx.emit(BattleEvent.message("The rain stopped."))
```

**Leech Seed (volatile on the seeded Pokémon)**
```gdscript
class_name LeechSeedEffect extends BattleEffect
var source_side: BattleSide
func on_end_of_turn(ctx):
    var drained := max(1, ctx.owner.max_hp / 8)
    ctx.damage(ctx.owner, drained)
    ctx.heal(ctx.session.active(source_side), drained)
    ctx.emit(BattleEvent.message("%s's health is sapped by Leech Seed!" % ctx.owner.name))
```
Because it's a volatile on `BattlePokemon`, switching out removes it automatically. Grass types are immune, which the *move's* try-hit check handles.

**Substitute (volatile with its own HP)**
```gdscript
class_name SubstituteEffect extends BattleEffect
var hp: int
func on_try_hit(ctx):
    if ctx.move.is_damaging() and not ctx.move.flags.has("sound"):
        ctx.redirect_damage_to(self)   # damage goes to hp; at 0, remove self
        return false                   # the real Pokémon isn't hit
    if ctx.move.targets_opponent():
        return false                   # status moves fail against a sub
    return true
```

**Intimidate (ability)**
```gdscript
func on_switch_in(ctx):
    ctx.change_stage(ctx.opponent, Stat.ATTACK, -1)
```

**Paralysis (status, moved onto the hook system)**
```gdscript
func on_before_move(ctx): return ctx.rng.randf() >= 0.25
func modify_speed(ctx, spd): return spd * 0.5
```

Adding a new ability or weather means **one new class plus one registry entry**, without editing the engine.

### 4. Damage as a chain of modifiers

```
base = ((2 × level / 5 + 2) × power × A / D) / 50 + 2
× critical (1.5) × random (0.85–1.0)
× STAB (1.5) × type effectiveness (chart, cached)
→ then pass through every active effect's modify_damage()
   (weather, burn halving physical, Reflect/Light Screen, abilities, items)
```

Each rule is one entry in the chain, so adding one never means editing the formula.

### 5. Move effects from data, looked up by name

Keep the `effects` array in `moves.json`, and map each `kind` to a handler function:

```json
{ "id": "leech_seed", "category": "status", "effects": [
    { "kind": "apply_volatile", "volatile": "leech_seed", "target": "enemy" } ] }

{ "id": "ember", "category": "special", "power": 40, "effects": [
    { "kind": "status_chance", "status": "burn", "chance": 10, "target": "enemy" } ] }

{ "id": "rain_dance", "category": "status", "effects": [
    { "kind": "set_weather", "weather": "rain", "turns": 5 } ] }
```

Common handlers (`damage`, `stat_change`, `apply_status`, `status_chance`, `apply_volatile`, `heal`, `drain`, `recoil`, `set_weather`, `set_side_condition`, `multi_hit`) cover most moves as **data only**. Truly unusual moves get a custom handler (`"kind": "custom", "handler": "substitute"`).

At the same time, parse strings into enums once when `MoveDatabase` loads (type, category, status, target), and index moves in a dictionary by id.

### 6. Events stay structured; the controller does the wording

The engine emits facts, for example `STAT_STAGE_CHANGED {side, stat, delta}` and `WEATHER_STARTED {weather}`. All message wording lives in one place on the controller/UI side. Today the stat-change wording is inside the engine.

### 7. Seeded RNG and tests

`BattleSession` owns a `RandomNumberGenerator`; every roll (accuracy, crit, damage spread, speed ties, secondary chances, paralysis) uses it. With the engine pure and seeded, a headless test can:

```
session = make_session(seed=42, player=[Ignewt lv10], enemy=[Minket lv10])
events  = engine.resolve_turn(session, move(0), move(1))
assert enemy.hp == 23 and events.has(STAT_STAGE_CHANGED)
```

This is what stops interactions (Substitute + Leech Seed + Rain) from quietly breaking each other as mechanics are added.

---

## Suggested implementation order

1. **Fix the logged bugs (#2–#7).**
2. **State layers + seeded RNG.** Add `FieldState`, `SideState`, volatiles on `BattlePokemon`, RNG on the session; move running away into the engine.
3. **Turn pipeline.** Restructure `resolve_turn` into the steps above; fold in accuracy, priority, PP and end of turn (#8).
4. **`BattleEffect` + registry.** Prove the pattern by moving burn and paralysis onto it, then add Rain/Sun.
5. **Move effect handlers.** Convert `moves.json` effects; add Leech Seed and Substitute.
6. **Abilities and items** as `BattleEffect` subclasses.

Each step leaves the game playable.

## Proposed issue breakdown

*(Not logged yet. Review first.)*

- Milestone: **Battle Engine v2** (include #2–#8)
- Parent issues: (1) State layers + RNG, (2) Turn pipeline, (3) BattleEffect hooks, (4) Data-driven move effects
- Sub-issues per mechanic: Rain/Sun, Leech Seed, Substitute, Protect, Reflect/Light Screen, Spikes, Intimidate, Levitate, pinch abilities (Blaze/Torrent/Overgrow), confusion, flinch, crits + full damage formula, burn/paralysis migration
- Labels: `mechanic:weather`, `mechanic:ability`, `mechanic:move`, `mechanic:status`

## Open questions

- ~~Physical/special split by type (Gen 3) or per move (Gen 4+)?~~ **Decided: per move**, via each move's `category`. Any other place where generations differ still needs a decision.
- Any region-specific (Far North) abilities, weather (hail/snow?) or moves to design for from the start?
- Single battles only, or should state and targeting leave room for doubles?
- Should held items come in with abilities (step 6), or later?
