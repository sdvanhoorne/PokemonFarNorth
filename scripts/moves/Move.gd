class_name Move

var id: int
var name = ""
var power = 0
var type = ""
var category = ""
var target = ""
var target_stat = ""
var stat_multiplier = 1.0
var accuracy = 1.0
var description = ""

func _init(move_data: Dictionary):
	id = int(move_data.get("id"))
	name = move_data.get("name")
	power = move_data.get("power")
	type = move_data.get("type")
	target = move_data.get("target")
	target_stat = move_data.get("target_stat")
	stat_multiplier = move_data.get("stat_multiplier")
	category = move_data.get("category")
	accuracy = move_data.get("accuracy")
	description = move_data.get("description")
