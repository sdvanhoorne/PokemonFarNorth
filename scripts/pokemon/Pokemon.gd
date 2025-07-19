class_name Pokemon

var base_data: PokemonBase

var level = 0
var current_hp
var current_xp = 0
var xp_to_next_level = 10
var moves = []
var status = ""

var stats = null
var battle_stats = null

func _init(data := {}):
	base_data = PokemonBase.new(data["id"])
	level = data.get("level")
	status = data.get("status")
	current_hp = data.get("current_hp")
	stats = PokemonStats.new(data.get("stats"))
	current_xp = data.get("current_xp")
	battle_stats = stats
	moves = data["moves"]

static func new_wild(level: int, data = {}) -> Pokemon:
	var pokemon = Pokemon.new({
		"base_stats": PokemonBase.new(data["id"]),
		"level": level,
		"stats": PokemonStats.scaled_stats(level, data.get("base_stats")),
		"moves": []
	})
	
	pokemon.battle_stats = pokemon.stats
	pokemon.current_hp = pokemon.battle_stats.hp
		
	var all_moves = data.get("moves", [])
	var learned_moves := []

	# Keep only moves the Pokémon can learn at or before its level
	for move_entry in all_moves:
		if move_entry["level"] <= level:
			learned_moves.append(move_entry)

	# Sort moves by level descending
	learned_moves.sort_custom(func(a, b): return b["level"] - a["level"])

	# Take the top 4 (latest learned)
	for move in learned_moves.slice(0, 4):
		pokemon.Moves.append(move["name"])
		
	return pokemon
	
func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		level += 1
		xp_to_next_level = calculate_xp_to_next(level)
		print(base_data.name + " leveled up to " + str(level))
		# Apply stat increases
		
func calculate_xp_to_next(level: int) -> int:
	return level * level * level
	
func recalculate_stats_on_level_up() -> void:
	battle_stats = PokemonStats.scaled_stats(level, base_data.base_stats)
	current_hp = battle_stats.hp	
