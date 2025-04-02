class_name Pokemon

var name = ""
var level = 1
var type = ""
var max_hp = 0
var current_hp = 0
var attack = 0
var defense = 0
var moves = []

func _init(data):
	name = data["name"]
	level = data["level"]
	type = data["type"]
	max_hp = data["max_hp"]
	current_hp = max_hp
	attack = data["attack"]
	defense = data["defense"]
	moves = data["moves"]
