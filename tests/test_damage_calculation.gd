extends TestCase
## Tests for scripts/battle/DamageCalculation.gd

func test_type_effectiveness_values() -> void:
	var calc := DamageCalculation.new()
	check_approx(calc.get_type_effectiveness("fire", "grass"), 2.0, "fire -> grass")
	check_approx(calc.get_type_effectiveness("fire", "water"), 0.5, "fire -> water")
	check_approx(calc.get_type_effectiveness("normal", "ghost"), 0.0, "normal -> ghost")
	check_approx(calc.get_type_effectiveness("normal", "normal"), 1.0, "normal -> normal")

func test_type_effectiveness_ignores_case() -> void:
	# Move data uses "fire"; species data uses "Fire".
	var calc := DamageCalculation.new()
	check_approx(calc.get_type_effectiveness("Fire", "Grass"), 2.0, "Fire -> Grass")

func test_unknown_type_defaults_to_neutral() -> void:
	var calc := DamageCalculation.new()
	check_approx(calc.get_type_effectiveness("fire", "not_a_type"), 1.0, "unknown defender type")
	check_approx(calc.get_type_effectiveness("not_a_type", "fire"), 1.0, "unknown move type")

## Physical/special is decided per move (move.category), not by move type (Gen 4+ rule).
## Attacker is strong physically and weak specially, so a physical move must hit much harder.
func test_split_uses_move_category_not_type() -> void:
	var calc := DamageCalculation.new()
	var attacker := _battler({"attack": 100, "special_attack": 10, "defense": 50, "special_defense": 50})
	var defender := _battler({"attack": 50, "special_attack": 50, "defense": 50, "special_defense": 50})

	# Fire was "special" by type in Gen 3; here a physical Fire move must use Attack.
	var fire_physical := calc.get_damage(_move("fire", "physical"), attacker, defender)
	var fire_special := calc.get_damage(_move("fire", "special"), attacker, defender)
	check(fire_physical > fire_special * 5,
		"physical Fire move uses Attack (physical %d, special %d)" % [fire_physical, fire_special])

	# Normal was "physical" by type in Gen 3; here a special Normal move must use Sp. Atk.
	var normal_physical := calc.get_damage(_move("normal", "physical"), attacker, defender)
	var normal_special := calc.get_damage(_move("normal", "special"), attacker, defender)
	check(normal_physical > normal_special * 5,
		"special Normal move uses Sp. Atk (physical %d, special %d)" % [normal_physical, normal_special])

func test_split_uses_matching_defense_stat() -> void:
	var calc := DamageCalculation.new()
	var attacker := _battler({"attack": 50, "special_attack": 50, "defense": 50, "special_defense": 50})
	var defender := _battler({"attack": 50, "special_attack": 50, "defense": 200, "special_defense": 10})

	var physical := calc.get_damage(_move("normal", "physical"), attacker, defender)
	var special := calc.get_damage(_move("normal", "special"), attacker, defender)
	check(special > physical * 5,
		"physical hits Defense, special hits Sp. Def (physical %d, special %d)" % [physical, special])

# Issue #3: STAB was never given to single types (case mismatch) and always given to dual types.
const IGNEWT := 7    # Fire
const CHASMURK := 24  # Water / Dragon

func test_stab_single_type_matching_move() -> void:
	var calc := DamageCalculation.new()
	var ignewt := BattlePokemon.new(Pokemon.new_wild(IGNEWT, 10))
	check(calc.has_stab(_move("fire", "special"), ignewt), "Fire type using a fire move gets STAB")

func test_stab_single_type_other_move() -> void:
	var calc := DamageCalculation.new()
	var ignewt := BattlePokemon.new(Pokemon.new_wild(IGNEWT, 10))
	check(not calc.has_stab(_move("normal", "physical"), ignewt), "Fire type using a normal move: no STAB")

func test_stab_dual_type_matches_either_type() -> void:
	var calc := DamageCalculation.new()
	var chasmurk := BattlePokemon.new(Pokemon.new_wild(CHASMURK, 10))
	check(calc.has_stab(_move("water", "special"), chasmurk), "matches type1")
	check(calc.has_stab(_move("dragon", "special"), chasmurk), "matches type2")

func test_stab_dual_type_other_move() -> void:
	var calc := DamageCalculation.new()
	var chasmurk := BattlePokemon.new(Pokemon.new_wild(CHASMURK, 10))
	check(not calc.has_stab(_move("normal", "physical"), chasmurk), "Water/Dragon using a normal move: no STAB")

func test_typeless_move_gets_no_stab() -> void:
	# An unknown move from MoveDatabase has type "", which must not match an empty type2.
	var calc := DamageCalculation.new()
	var ignewt := BattlePokemon.new(Pokemon.new_wild(IGNEWT, 10))
	check(not calc.has_stab(Move.new({}), ignewt), "typeless move: no STAB")

func test_stab_multiplies_damage_by_one_and_a_half() -> void:
	# Same stats, same neutral matchup; only the attacker's type differs.
	var calc := DamageCalculation.new()
	var stats := {"hp": 100, "attack": 60, "defense": 60, "special_attack": 60, "special_defense": 60, "speed": 60}
	var fire_user := _battler_of(IGNEWT, stats)
	var normal_user := _battler_of(1, stats)  # Minket is Grass, so fire is not STAB for it
	var defender := _battler_of(1, stats)
	var ember := Move.new({"name": "Test", "type": "fire", "category": "special", "power": 90, "effects": []})
	var with_stab := calc.get_damage(ember, fire_user, defender)
	var without := calc.get_damage(ember, normal_user, defender)
	check(absf(with_stab - without * 1.5) <= 1.0,
		"STAB damage ~1.5x (with %d, without %d)" % [with_stab, without])

func _battler_of(species_id: int, stat_values: Dictionary) -> BattlePokemon:
	var pokemon := Pokemon.new_wild(species_id, 10)
	pokemon.stats = PokemonStats.new(stat_values)
	return BattlePokemon.new(pokemon)

func _battler(stat_values: Dictionary) -> BattlePokemon:
	var pokemon := Pokemon.new_wild(1, 10)
	stat_values["hp"] = 100
	pokemon.stats = PokemonStats.new(stat_values)
	return BattlePokemon.new(pokemon)

func _move(type: String, category: String) -> Move:
	return Move.new({"name": "Test Move", "type": type, "category": category, "power": 60, "effects": []})

func test_type_chart_is_cached_not_reread() -> void:
	# Issue #7: the chart must be read once and reused, not reloaded per lookup.
	DamageCalculation.new().get_type_effectiveness("fire", "grass")
	var original := DamageCalculation._type_chart
	check(not original.is_empty(), "chart loaded after first lookup")

	# Swap in a fake chart. If lookups still hit the disk, they'd return the real value (2.0).
	DamageCalculation._type_chart = {"fire": {"grass": 99.0}}
	check_approx(DamageCalculation.new().get_type_effectiveness("fire", "grass"), 99.0,
		"new instance reads the cached chart")
	DamageCalculation._type_chart = original
