extends Node

const MAPS: Dictionary = {
	"starting_house": preload("res://scenes/world/towns/starting_town/StartingHouse.tscn"),
	"starting_town":  preload("res://scenes/world/towns/starting_town/StartingTown.tscn"),
	"starting_town_lab":  preload("res://scenes/world/towns/starting_town/StartingTownLab.tscn"),
	"route_01":  preload("res://scenes/world/routes/Route01.tscn"),
	"maple_city":  preload("res://scenes/world/towns/maple_city/MapleCity.tscn"),
	"cave_01":  preload("res://scenes/world/caves/Cave01.tscn"),
}

func get_map(map_id: String) -> PackedScene:
	var scene: PackedScene = MAPS.get(map_id)
	if scene == null:
		push_error("MapRegistry: unknown map_id '%s'" % map_id)
	return scene
