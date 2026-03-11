class_name Move

var id: int
var name: String = ""
var power: int = 0
var type: String = ""
var category: String = ""
var target: String = ""
var target_stat: String = ""
var stat_multiplier: float = 1.0
var accuracy: float = 1.0
var description: String = ""

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
