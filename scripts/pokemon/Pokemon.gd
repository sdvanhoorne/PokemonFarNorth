class_name Pokemon

const stat_scaler = 25
const starting_hp = 10

var id = 0
var name = ""
var level = 0
var type1 = ""
var type2 = ""
var hp = 0
var current_hp
var attack = 0
var special_attack = 0
var defense = 0
var special_defense = 0
var speed = 0
var moves = []

func _init(data = {}, generatedLevel = 1):
	id = data["id"]
	name = data["name"]
	
	# this section is wack
	# need a better way to generate a pokemon at a certain level
	# also need constructor for party pokemon that may have existing 
	# status effects or hp loss
	var lvl = data.get("level")
	level = lvl if lvl else generatedLevel
	type1 = data["type1"]
	type2 = data["type2"]
	
	# this section is also wack
	# need a better way to track base stats vs current stats
	var currentHp = data.get("current_hp")
	if(currentHp == null):
		hp = scale_stat(data["base_stats"]["hp"]) + starting_hp
		current_hp = hp
		attack = scale_stat(data["base_stats"]["attack"])
		special_attack = scale_stat(data["base_stats"]["special_attack"])
		defense = scale_stat(data["base_stats"]["defense"])
		special_defense = scale_stat(data["base_stats"]["special_defense"])
		speed = scale_stat(data["base_stats"]["speed"])
	else:
		hp = data["base_stats"]["hp"]
		current_hp = currentHp
		attack = data["base_stats"]["attack"]
		special_attack = data["base_stats"]["special_attack"]
		defense = data["base_stats"]["defense"]
		special_defense = data["base_stats"]["special_defense"]
		speed = data["base_stats"]["speed"]
	
	moves = data["moves"]

func scale_stat(stat: int):
	return stat * (int(level) / stat_scaler)
