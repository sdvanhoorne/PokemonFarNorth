class_name Pokemon

var id = 0
var name = ""
var level = 0
var type1 = ""
var type2 = ""
var max_hp = 0
var current_hp = 0
var attack = 0
var special_attack = 0
var defense = 0
var special_defense = 0
var speed = 0
var moves = []

func _init(data):
	id = data["id"]
	name = data["name"]
	level = data["level"]
	type1 = data["type1"]
	type2 = data["type2"]
	max_hp = data["max_hp"]
	current_hp = max_hp
	attack = data["attack"]
	attack = data["special_attack"]
	defense = data["defense"]
	attack = data["special_defense"]
	attack = data["speed"]
	moves = data["moves"]
