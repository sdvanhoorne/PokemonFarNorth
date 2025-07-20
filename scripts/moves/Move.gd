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
	var file = FileAccess.open("res://data/moves.json", FileAccess.READ)
	var all_data = JSON.parse_string(file.get_as_text())
	var move_data = all_data[str(id)]
	id = id
	name = move_data.get("name")
	damage = move_data.get("damage")
	type = move_data.get("type")
	target = move_data.get("target")
	target_stat = move_data.get("target_stat")
	stat_multiplier = move_data.get("stat_multiplier")
	category = move_data.get("category")
	accuracy = move_data.get("accuracy")
	description = move_data.get("description")
