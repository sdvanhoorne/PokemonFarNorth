extends Node

var _reserved_tiles: Dictionary = {}
var _occupied_tiles: Dictionary = {}

func _tile_key(pos: Vector2) -> Vector2i:
	return Vector2i(roundi(pos.x / GlobalConstants.tile_size), roundi(pos.y / GlobalConstants.tile_size))

func clear_all() -> void:
	_reserved_tiles.clear()
	_occupied_tiles.clear()

func set_occupied(world_pos: Vector2, mover: Node) -> void:
	_occupied_tiles[_tile_key(world_pos)] = mover

func clear_occupied(world_pos: Vector2, mover: Node) -> void:
	var key := _tile_key(world_pos)
	if _occupied_tiles.get(key) == mover:
		_occupied_tiles.erase(key)

func reserve_tile(world_pos: Vector2, mover: Node) -> bool:
	var key := _tile_key(world_pos)

	if _reserved_tiles.has(key) and _reserved_tiles[key] != mover:
		return false

	if _occupied_tiles.has(key) and _occupied_tiles[key] != mover:
		return false

	_reserved_tiles[key] = mover
	return true

func release_reserved(world_pos: Vector2, mover: Node) -> void:
	var key := _tile_key(world_pos)
	if _reserved_tiles.get(key) == mover:
		_reserved_tiles.erase(key)

func is_blocked(world_pos: Vector2, mover: Node = null) -> bool:
	var key := _tile_key(world_pos)

	if _reserved_tiles.has(key) and _reserved_tiles[key] != mover:
		return true

	if _occupied_tiles.has(key) and _occupied_tiles[key] != mover:
		return true

	return false
