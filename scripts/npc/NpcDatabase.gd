extends Node

var npcs: Dictionary = {}

func _ready() -> void:
	var file := FileAccess.open("res://data/npc/npcs.json", FileAccess.READ)
	if file == null:
		push_error("Could not open npcs.json")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		npcs = parsed
	else:
		push_error("Invalid npcs.json format")

func get_npc_data(id: String) -> Dictionary:
	if npcs.has(id):
		return npcs[id]
	return npcs.get("default_npc", {})
