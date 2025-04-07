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
	var lvl = data.get("level")
	level = lvl if lvl else 0
	type1 = data["type1"]
	type2 = data["type2"]
	# todo turn base stats into real stats
	hp = data["base_stats"]["hp"]
	attack = data["base_stats"]["attack"]
	special_attack = data["base_stats"]["special_attack"]
	defense = data["base_stats"]["defense"]
	special_defense = data["base_stats"]["special_defense"]
	speed = data["base_stats"]["speed"]
	
	var currentHp = data.get("current_hp")
	current_hp = currentHp if currentHp else hp
	
	moves = data["moves"]
