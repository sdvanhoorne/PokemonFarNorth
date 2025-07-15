class_name Pokemon

var Id = 0
var Name = ""
var Level = 0
var Type1 = ""
var Type2 = ""
var Current_Hp
var Current_Xp = 0
var Xp_To_Next_Level = 10
var Moves = []
var Status = ""

var CurrentStats = null
var BattleStats = null
var BaseStats = null

func _init(data := {}):
	Id = data["Id"]
	Name = data["Name"]
	Type1 = data["Type1"]
	Type2 = data["Type2"]
	Level = data.get("Level")
	Status = data.get("Status")
	Current_Hp = data.get("Current_Hp")
	CurrentStats = PokemonStats.new(data.get("Stats"))
	Current_Xp = data.get("Current_Xp")
	BattleStats = CurrentStats
	BaseStats = null 
	# need to get base stats from base pokemon json
	# BaseStats = PokemonStats.new(data.get("BaseStats"))
	Moves = data["Moves"]

static func new_wild(level: int, data = {}) -> Pokemon:
	var pokemon = Pokemon.new({
		"Id": data.get("Id"),
		"Name": data.get("Name"),
		"Type1": data.get("Type1"),
		"Type2": data.get("Type2"),
		"Level": level,
		"Stats": PokemonStats.scaled_stats(level, data.get("Base_Stats")),
		"Moves": []
	})
	
	pokemon.BattleStats = pokemon.CurrentStats
	pokemon.Current_Hp = pokemon.BattleStats.Hp
		
	var all_moves = data.get("Moves", [])
	var learned_moves := []

	# Keep only moves the Pokémon can learn at or before its level
	for move_entry in all_moves:
		if move_entry["Level"] <= level:
			learned_moves.append(move_entry)

	# Sort moves by level descending
	learned_moves.sort_custom(func(a, b): return b["Level"] - a["Level"])

	# Take the top 4 (latest learned)
	for move in learned_moves.slice(0, 4):
		pokemon.Moves.append(move["Name"])
		
	return pokemon
	
func add_xp(amount: int) -> void:
	Current_Xp += amount
	while Current_Xp >= Xp_To_Next_Level:
		Level += 1
		Xp_To_Next_Level = calculate_xp_to_next(Level)
		print(Name + " leveled up to " + str(Level))
		# Apply stat increases
		
func calculate_xp_to_next(level: int) -> int:
	return level * level * level
	
func recalculate_stats_on_level_up() -> void:
	BattleStats = PokemonStats.scaled_stats(Level, BaseStats)
	Current_Hp = BattleStats.Hp	
