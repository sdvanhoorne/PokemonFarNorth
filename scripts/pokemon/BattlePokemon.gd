class_name BattlePokemon
extends RefCounted

enum Stat {
	ATTACK,
	DEFENSE,
	SPECIAL_ATTACK,
	SPECIAL_DEFENSE,
	SPEED,
	ACCURACY,
	EVASION
}

var pokemon: Pokemon

var stat_stages: Dictionary = {
	Stat.ATTACK: 0,
	Stat.DEFENSE: 0,
	Stat.SPECIAL_ATTACK: 0,
	Stat.SPECIAL_DEFENSE: 0,
	Stat.SPEED: 0,
	Stat.ACCURACY: 0,
	Stat.EVASION: 0
}

func _init(p_pokemon: Pokemon) -> void:
	pokemon = p_pokemon

func get_stat_stage(stat: Stat) -> int:
	return stat_stages[stat]

func change_stat_stage(stat: Stat, amount: int) -> int:
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
