class_name Pokemon

var id = 0
var name = ""
var level = 0
var type1 = ""
var type2 = ""
var hp = 0
var current_hp = 0
var attack = 0
var special_attack = 0
var defense = 0
var special_defense = 0
var speed = 0
var moves = []

func _init(data = {}):
	id = data["id"]
	name = data["name"]
	level = data["level"]
	type1 = data["type1"]
	type2 = data["type2"]
	current_hp = data["current_hp"]
	hp = data["base_stats"]["hp"]
	attack = data["base_stats"]["attack"]
	special_attack = data["base_stats"]["special_attack"]
	defense = data["base_stats"]["defense"]
	special_defense = data["base_stats"]["special_defense"]
	speed = data["base_stats"]["speed"]
	moves = data["moves"]
