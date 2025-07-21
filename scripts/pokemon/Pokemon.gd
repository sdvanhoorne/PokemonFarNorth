class_name Pokemon

var base_data: PokemonBase

var level = 0
var current_hp
var current_xp = 0
var xp_to_next_level = 0
var move_ids = []
var moves = []
var status = ""

var stats = null
var battle_stats = null

func _init(id: int):
	var path = "res://data/pokemon/%s.json" % Pokedex.pokedex[id]
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	base_data = PokemonBase.new(data["id"])
	
static func new_existing(data: Dictionary) -> Pokemon:
	var pokemon = Pokemon.new(data.get("id"))
	pokemon.level = int(data.get("level"))
	pokemon.status = data.get("status")
	pokemon.current_xp = data.get("current_xp")
	pokemon.move_ids = data["move_ids"]
	pokemon.stats = data.get("stats")
	# might want to set battle_stats right before battle
	pokemon.battle_stats = pokemon.stats
	pokemon.current_hp = data.get("current_hp")
	pokemon.xp_to_next_level = calculate_xp_to_next(pokemon.level)
	return pokemon

static func new_wild(id: int, level: int) -> Pokemon:		
	var pokemon = Pokemon.new(id)
	pokemon.level = level
	pokemon.status = "None"
	pokemon.move_ids = get_learned_moves(level, pokemon.base_data.learnable_moves)
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
	return learned_moves.slice(0, 4).map(func(move): return move["id"])

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		level += 1
		xp_to_next_level = calculate_xp_to_next(level)
		print(base_data.name + " leveled up to " + str(level))
		# Apply stat increases
		
static func calculate_xp_to_next(_level: int) -> int:
	# cubic so that lvl 100 ^ 3 = 1,000,000 xp needed for final level
	var level = _level - 1
	return level * level * level
	
func recalculate_stats_on_level_up() -> void:
	battle_stats = PokemonStats.scaled_stats(level, base_data.base_stats)
	current_hp = battle_stats.hp	

static func get_xp_given(level: int) -> int:
	return level * level * level / 4
