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
var effects: Array = []

func _init(move_data: Dictionary):
	id = int(move_data.get("id", 0))
	name = move_data.get("name", "")
	power = int(move_data.get("power", 0))
	type = move_data.get("type", "") 
	target = move_data.get("target", "") 
	target_stat = move_data.get("target_stat", "")
	stat_multiplier = float(move_data.get("stat_multiplier", 1.0))
	category = move_data.get("category", "")
	accuracy = float(move_data.get("accuracy", 1.0))
	description = move_data.get("description", "")
	for effect in move_data.get("effects"):
		effects.append(MoveEffect.new(
			effect.get("kind", ""),
			effect.get("target", ""),
			effect.get("stat", ""),
			int(effect.get("stages", 0)),
			int(effect.get("chance", 100))
		))
