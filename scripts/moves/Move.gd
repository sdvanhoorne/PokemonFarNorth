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
	id = int(move_data.get("id", 0))
	name = move_data.get("name") if move_data.get("name") != null else ""
	power = int(move_data.get("power", 0))
	type = move_data.get("type") if move_data.get("type") != null else ""
	target = move_data.get("target") if move_data.get("target") != null else ""
	target_stat = move_data.get("target_stat") if move_data.get("target_stat") != null else ""
	stat_multiplier = float(move_data.get("stat_multiplier", 1.0))
	category = move_data.get("category") if move_data.get("category") != null else ""
	accuracy = float(move_data.get("accuracy", 1.0))
	description = move_data.get("description") if move_data.get("description") != null else ""
