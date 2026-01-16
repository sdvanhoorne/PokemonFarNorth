class_name Pokemon

var base_data: PokemonBase

enum status_types { NONE, POISONED, ASLEEP, PARALYZED, BURNED, LOCKED }

var level = 0
var current_hp = 0
var current_xp = 0
var xp_to_next_level = 0
var move_names = []
var moves = []
var stats: PokemonStats = null
var battle_stats: PokemonStats = null
var status: status_types

func _init(id: int):
	var path = "res://data/pokemon/%s.json" % Pokedex.pokedex[id]
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	base_data = PokemonBase.new(data["id"])
	
static func new_existing(data: Dictionary) -> Pokemon:
	var pokemon = Pokemon.new(data.get("id"))
	pokemon.level = int(data.get("level"))
	pokemon.status = data.get("status")
	pokemon.current_xp = int(data.get("current_xp"))
	pokemon.move_names = data["move_names"]
	pokemon.stats = PokemonStats.new(data.get("stats"))
	# might want to set battle_stats right before battle
	pokemon.battle_stats = pokemon.stats
	pokemon.current_hp = int(data.get("current_hp"))
	pokemon.xp_to_next_level = calculate_xp_to_next(pokemon.level)
	return pokemon

static func new_wild(id: int, level: int) -> Pokemon:		
	var pokemon = Pokemon.new(id)
	pokemon.level = level
	pokemon.status = status_types.NONE
	pokemon.move_names = get_learned_moves(level, pokemon.base_data.learnable_moves)
	pokemon.stats = PokemonStats.scaled_stats(level, pokemon.base_data.base_stats)
	pokemon.battle_stats = pokemon.stats
	pokemon.current_hp = pokemon.battle_stats.hp		
	return pokemon

static func get_learned_moves(level: int, learnable_moves: Array) -> Array:
	var learned_moves = []

	for learnable_move in learnable_moves:
		if learnable_move["level"] <= level:
			learned_moves.append(learnable_move)

	learned_moves.sort_custom(func(a, b): return b["level"] - a["level"])
	return learned_moves.slice(0, 4).map(func(move): return move["name"])

func calculate_xp_given() -> int:
	# need function for amount of xp to give
	return 20

func add_xp(amount: int) -> void:
	current_xp += amount
	
func leveled_up() -> bool:
	if current_xp >= xp_to_next_level:
		_level_up()
		return true
	return false

func _level_up() -> void:
		level += 1
		xp_to_next_level = calculate_xp_to_next(level)
		recalculate_stats_on_level_up()
		
static func calculate_xp_to_next(_level: int) -> int:
	# cubic so that lvl 99 -> 100 = 1,000,000 xp
	var xp_to_next = _level * _level * _level
	return xp_to_next
	
func recalculate_stats_on_level_up() -> void:
	stats = PokemonStats.scaled_stats(level, base_data.base_stats)
	current_hp = battle_stats.hp
	battle_stats = stats

static func get_xp_given(level: int) -> int:
	return int(level * level * level / 4)
