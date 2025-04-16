class_name PokemonStats

const stat_scaler = 25.0
const starting_hp = 15

var Hp = 0
var Attack = 0
var Defense = 0
var Special_Attack = 0
var Special_Defense = 0
var Speed = 0

func _init(data := {}):
	Hp = data["Hp"]
	Attack = data["Attack"]
	Defense = data["Defense"]
	Special_Attack = data["Special_Attack"]
	Special_Defense = data["Special_Defense"]
	Speed = data["Speed"]
	
static func scaled_stats( level: int, data = {}):
	return {
		"Hp": scale_stat(data["Hp"], level) + starting_hp,
		"Attack": scale_stat(data["Attack"], level),
		"Defense": scale_stat(data["Defense"], level),
		"Special_Attack": scale_stat(data["Special_Attack"], level),
		"Special_Defense": scale_stat(data["Special_Defense"], level),
		"Speed": scale_stat(data["Speed"], level),
	}

static func scale_stat(stat: int, level: int) -> int:
	var scaled_stat = stat * (level / stat_scaler)
	return scaled_stat
