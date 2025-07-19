class_name Move

var id: int
var name = ""
var damage = 0
var type = ""
var category = ""
var target = ""
var target_stat = ""
var stat_multiplier = 1.0
var accuracy = 1.0
var description = ""

func _init(id: int):
	var moveData = FileAccess.open("res://data/moves.json", FileAccess.READ)
	id = 
	name = name
	damage = moveData.get("damage")
	type = moveData.get("type")
	target = moveData.get("target")
	target_stat = moveData.get("target_stat")
	stat_multiplier = moveData.get("stat_multiplier")
	category = moveData.get("category")
	accuracy = moveData.get("accuracy")
	description = moveData.get("description")
