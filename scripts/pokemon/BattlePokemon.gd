class_name BattlePokemon
extends RefCounted

var pokemon: Pokemon

# Keyed by PokemonStat.Stat (HP has no stage). Issue #2: this used to have its own
# enum that was offset by one from PokemonStat.Stat.
var stat_stages: Dictionary = {
	PokemonStat.Stat.ATTACK: 0,
	PokemonStat.Stat.DEFENSE: 0,
	PokemonStat.Stat.SPECIAL_ATTACK: 0,
	PokemonStat.Stat.SPECIAL_DEFENSE: 0,
	PokemonStat.Stat.SPEED: 0,
	PokemonStat.Stat.ACCURACY: 0,
	PokemonStat.Stat.EVASION: 0
}

func _init(p_pokemon: Pokemon) -> void:
	pokemon = p_pokemon

func get_stat_stage(stat: int) -> int:
	return stat_stages[stat]

func change_stat_stage(stat: int, amount: int) -> int:
	var old_stage: int = stat_stages[stat]
	var new_stage := clampi(old_stage + amount, -6, 6)

	stat_stages[stat] = new_stage

	return new_stage - old_stage
	
func get_effective_stat(stat: int) -> int:
	var base_stat: int = pokemon.stats.get_stat(stat)
	var stage: int = stat_stages[stat]

	var multiplier: float

	if stage >= 0:
		multiplier = float(2 + stage) / 2.0
	else:
		multiplier = 2.0 / float(2 - stage)

	return int(base_stat * multiplier)
