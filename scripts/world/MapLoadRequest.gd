extends RefCounted
class_name MapLoadRequest

enum PlacementType {
	SPAWN,
	POSITION
}

var map_id: String = ""
var placement_type: PlacementType = PlacementType.SPAWN

var spawn_name: String = ""
var horizontal: bool = true
var index: int = 0

var position: Vector2 = Vector2.ZERO
var facing_direction: String = "down"

static func make(
	map_id_: String,
	placement_type_: PlacementType,
	spawn_name_: String = "",
	horizontal_: bool = true,
	index_: int = 0,
	position_: Vector2 = Vector2.ZERO,
	facing_direction_: String = "down"
) -> MapLoadRequest:
	var request := MapLoadRequest.new()
	request.map_id = map_id_
	request.placement_type = placement_type_
	request.spawn_name = spawn_name_
	request.horizontal = horizontal_
	request.index = index_
	request.position = position_
	request.facing_direction = facing_direction_
	return request

static func for_spawn(
	map_id_: String,
	spawn_name_: String,
	facing_direction_: String = "down",
	horizontal_: bool = true,
	index_: int = 0
) -> MapLoadRequest:
	return make(
		map_id_,
		PlacementType.SPAWN,
		spawn_name_,
		horizontal_,
		index_,
		Vector2.ZERO,
		facing_direction_
	)

static func for_position(
	map_id_: String,
	position_: Vector2,
	facing_direction_: String = "down"
) -> MapLoadRequest:
	return make(
		map_id_,
		PlacementType.POSITION,
		"",
		true,
		0,
		position_,
		facing_direction_
	)
