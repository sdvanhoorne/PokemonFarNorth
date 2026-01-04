extends Node

const MAPS: Dictionary = {
	"starting_house": preload("res://scenes/world/towns/starting_town/starting_house.tscn"),
	"starting_town":  preload("res://scenes/world/towns/starting_town/starting_town.tscn"),
	"route_01":  preload("res://scenes/world/routes/route_01.tscn"),
	"maple_city":  preload("res://scenes/world/towns/maple_city/maple_city.tscn"),
	"cave_01":  preload("res://scenes/world/caves/cave_01.tscn"),
}

func get_map(map_id: String) -> PackedScene:
	var scene: PackedScene = MAPS.get(map_id)
	if scene == null:
		push_error("MapRegistry: unknown map_id '%s'" % map_id)
	return scene
