extends TestCase
## Tests for scripts/pokemon/BattlePokemon.gd

# Issue #2: stages must be keyed by PokemonStat.Stat, including accuracy/evasion.
func test_stat_stages_cover_every_stageable_stat() -> void:
	var battler := BattlePokemon.new(Pokemon.new_wild(1, 10))
	for stat in [
		PokemonStat.Stat.ATTACK, PokemonStat.Stat.DEFENSE,
		PokemonStat.Stat.SPECIAL_ATTACK, PokemonStat.Stat.SPECIAL_DEFENSE,
		PokemonStat.Stat.SPEED, PokemonStat.Stat.ACCURACY, PokemonStat.Stat.EVASION,
	]:
		check(battler.stat_stages.has(stat), "stage slot for %s" % PokemonStat.Stat.keys()[stat])
	check(not battler.stat_stages.has(PokemonStat.Stat.HP), "HP has no stage")

func test_evasion_stage_can_change() -> void:
	# On the old code this looked up a key that didn't exist and errored.
	var battler := BattlePokemon.new(Pokemon.new_wild(1, 10))
	check_eq(battler.change_stat_stage(PokemonStat.Stat.EVASION, 1), 1, "evasion +1 applied")
	check_eq(battler.get_stat_stage(PokemonStat.Stat.EVASION), 1, "evasion stage")

func test_stage_change_only_touches_named_stat() -> void:
	var battler := BattlePokemon.new(Pokemon.new_wild(1, 10))
	battler.change_stat_stage(PokemonStat.from_string("defense"), -1)  # Tail Whip
	check_eq(battler.get_stat_stage(PokemonStat.Stat.DEFENSE), -1, "defense")
	check_eq(battler.get_stat_stage(PokemonStat.Stat.ATTACK), 0, "attack untouched")
	check_eq(battler.get_stat_stage(PokemonStat.Stat.SPECIAL_ATTACK), 0, "sp. atk untouched")

func test_stage_affects_effective_stat() -> void:
	var pokemon := Pokemon.new_wild(1, 10)
	pokemon.stats = PokemonStats.new({"hp": 50, "attack": 40, "defense": 40,
		"special_attack": 40, "special_defense": 40, "speed": 40})
	var battler := BattlePokemon.new(pokemon)
	battler.change_stat_stage(PokemonStat.Stat.ATTACK, 2)
	check_eq(battler.get_effective_stat(PokemonStat.Stat.ATTACK), 80, "+2 attack doubles")
	check_eq(battler.get_effective_stat(PokemonStat.Stat.DEFENSE), 40, "defense unchanged")

func test_stages_clamp_at_six() -> void:
	var battler := BattlePokemon.new(Pokemon.new_wild(1, 10))
	battler.change_stat_stage(PokemonStat.Stat.SPEED, 5)
	check_eq(battler.change_stat_stage(PokemonStat.Stat.SPEED, 3), 1, "only 1 stage left")
	check_eq(battler.get_stat_stage(PokemonStat.Stat.SPEED), 6, "capped at +6")
