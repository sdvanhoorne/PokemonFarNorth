class_name PokemonStats

const stat_scaler = 25.0
const starting_hp = 15

var hp = 0
var attack = 0
var defense = 0
var special_attack = 0
var special_defense = 0
var speed = 0

func _init(data := {}):
	hp = data["hp"]
	attack = data["attack"]
	defense = data["defense"]
	special_attack = data["special_attack"]
	special_defense = data["special_defense"]
	speed = data["speed"]
	
static func scaled_stats( level: int, data = {}) -> PokemonStats:
	return PokemonStats.new({
		"hp": scale_stat(data["hp"], level) + starting_hp,
		"attack": scale_stat(data["attack"], level),
		"defense": scale_stat(data["defense"], level),
		"special_attack": scale_stat(data["special_attack"], level),
		"special_defense": scale_stat(data["special_defense"], level),
		"speed": scale_stat(data["speed"], level),
	})

static func scale_stat(stat: int, level: int) -> int:
	var scaled_stat = stat * (level / stat_scaler)
	return scaled_stat
