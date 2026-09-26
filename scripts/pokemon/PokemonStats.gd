extends RefCounted
class_name PokemonStats

const stat_scaler = 25.0
const starting_hp = 15

var values: Dictionary = {
	PokemonStat.Stat.HP: 0,
	PokemonStat.Stat.ATTACK: 0,
	PokemonStat.Stat.DEFENSE: 0,
	PokemonStat.Stat.SPECIAL_ATTACK: 0,
	PokemonStat.Stat.SPECIAL_DEFENSE: 0,
	PokemonStat.Stat.SPEED: 0
}

func _init(data: Dictionary = {}) -> void:
	values[PokemonStat.Stat.HP] = int(data.get("hp", 0))
	values[PokemonStat.Stat.ATTACK] = int(data.get("attack", 0))
	values[PokemonStat.Stat.DEFENSE] = int(data.get("defense", 0))
	values[PokemonStat.Stat.SPECIAL_ATTACK] = int(data.get("special_attack", 0))
	values[PokemonStat.Stat.SPECIAL_DEFENSE] = int(data.get("special_defense", 0))
	values[PokemonStat.Stat.SPEED] = int(data.get("speed", 0))

func get_stat(stat: int) -> int:
	return values[stat]

# for calculating new stats after level up
	
static func scaled_stats(level: int, data: PokemonStats) -> PokemonStats:
	return PokemonStats.new({
		"hp": scale_stat(data.get_stat(PokemonStat.Stat.HP), level) + starting_hp,
		"attack": scale_stat(data.get_stat(PokemonStat.Stat.ATTACK), level),
		"defense": scale_stat(data.get_stat(PokemonStat.Stat.DEFENSE), level),
		"special_attack": scale_stat(data.get_stat(PokemonStat.Stat.SPECIAL_ATTACK), level),
		"special_defense": scale_stat(data.get_stat(PokemonStat.Stat.SPECIAL_DEFENSE), level),
		"speed": scale_stat(data.get_stat(PokemonStat.Stat.SPEED), level),
	})

static func scale_stat(stat: int, level: int) -> int:
	return int(stat * (level / stat_scaler))

## Returns stat total
func get_total() -> int:
	return values.values().reduce(func(sum, value): return sum + value, 0)
