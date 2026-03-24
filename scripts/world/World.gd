extends Node2D

const PlayerScene = preload("res://scenes/player/Player.tscn")

var current_map: Node2D = null
var is_loading_map := false

@onready var menu := $GameMenuCanvas
@onready var map_name_control: Control = $MapNameCanvas/MapName

var menu_open := false

func _ready() -> void:
	DialogueManager.message_box = get_node_or_null("/root/World/DialogueCanvas/MessageBox")

func load_map(request: MapLoadRequest, player: Node2D = null) -> Node2D:
	if is_loading_map:
		return current_map

	is_loading_map = true

	var new_map := _instantiate_map(request.map_id)
	if new_map == null:
		is_loading_map = false
		return current_map

	var old_map := current_map
	player = _get_or_create_player(player)

	_attach_map_and_player(new_map, player)
	_place_player(player, new_map, request)
	_reset_player_after_transfer(player)
	_finalize_map_swap(old_map, new_map, request, player)

	is_loading_map = false
	return current_map

func _instantiate_map(map_id: String) -> Node2D:
	var packed_scene := MapRegistry.get_map(map_id)
	if packed_scene == null:
		push_error("World: failed to load map '%s'" % map_id)
		return null

	return packed_scene.instantiate()

func _get_or_create_player(player: Node2D) -> Node2D:
	if player == null:
		return PlayerScene.instantiate()

	var prev_parent := player.get_parent()
	if prev_parent != null:
		prev_parent.remove_child(player)

	return player

func _attach_map_and_player(new_map: Node2D, player: Node2D) -> void:
	current_map = new_map
	add_child(current_map)
	current_map.get_node("SortY").add_child(player)
	GridMovementRegistry.clear_all()

func _place_player(player: Node2D, map: Node2D, request: MapLoadRequest) -> void:
	match request.placement_type:
		MapLoadRequest.PlacementType.SPAWN:
			_place_player_at_spawn(player, map, request)
		MapLoadRequest.PlacementType.POSITION:
			_place_player_at_position(player, request.position, request.facing_direction)
		_:
			push_warning("World: unknown placement type for map '%s'" % request.map_id)
			_place_player_at_position(player, Vector2.ZERO, "down")

func _place_player_at_spawn(player: Node2D, map: Node2D, request: MapLoadRequest) -> void:
	if request.spawn_name == "":
		push_warning("World: spawn placement requested without a spawn_name on map '%s'" % request.map_id)
		_apply_player_transform(player, Vector2.ZERO, request.facing_direction)
		return

	var spawns := map.get_node_or_null("Spawns")
	if spawns == null:
		push_warning("World: map '%s' is missing a Spawns node" % request.map_id)
		_apply_player_transform(player, Vector2.ZERO, request.facing_direction)
		return

	var spawn := spawns.get_node_or_null(request.spawn_name)
	if spawn == null:
		push_warning("World: spawn '%s' not found on map '%s'" % [request.spawn_name, request.map_id])
		_apply_player_transform(player, Vector2.ZERO, request.facing_direction)
		return

	var tile := Vector2(GlobalConstants.tile_size, GlobalConstants.tile_size)
	var base_pos = spawn.global_position.snapped(tile)
	var offset := Vector2(request.index * GlobalConstants.tile_size, 0) if request.horizontal else Vector2(0, request.index * GlobalConstants.tile_size)
	var final_pos = base_pos + offset

	_apply_player_transform(player, final_pos, request.facing_direction)

func _place_player_at_position(player: Node2D, position: Vector2, facing_direction: String) -> void:
	var snapped_pos := position.snapped(Vector2(GlobalConstants.tile_size, GlobalConstants.tile_size))
	_apply_player_transform(player, snapped_pos, facing_direction)

func _apply_player_transform(player: Node2D, position: Vector2, facing_direction: String) -> void:
	player.global_position = position
	player.movement_controller.target_position = position
	player.movement_controller.facing_direction = facing_direction
	player.movement_controller.clear_input()

func _reset_player_after_transfer(player: Node2D) -> void:
	player.movement_controller.is_moving = false
	player.movement_controller.sprinting = false
	player.movement_controller.hold_timer = 0.0
	player.movement_controller.facing_input = Vector2.ZERO
	player.movement_controller.body.velocity = Vector2.ZERO

func _finalize_map_swap(old_map: Node2D, new_map: Node2D, request: MapLoadRequest, player: Node2D) -> void:
	if old_map != null:
		old_map.queue_free()

	new_map.map_id = request.map_id
	GameState.current_map_id = request.map_id
	GameState.player_position = player.global_position
	GameState.player_facing_direction = player.movement_controller.facing_direction

	var map_display_name = new_map.get("map_display_name")
	if map_display_name != null:
		map_name_control.show_map_name_card(map_display_name)

func capture_runtime_state() -> void:
	if current_map == null:
		return

	var player = current_map.get_node_or_null("SortY/Player")
	if player == null:
		return

	GameState.current_map_id = current_map.map_id
	GameState.player_position = player.global_position
	GameState.player_facing_direction = player.movement_controller.facing_direction

func _on_home_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	var request := MapLoadRequest.for_spawn("starting_town", "StartingHouseSpawn", "down")
	load_map(request)

func _on_battle_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	var encounteredPokemon = Pokemon.new_wild(14, 1)
	BattleManager.start_wild_battle([encounteredPokemon], Vector2(0, 0), Vector2(0, 0), "")

func _on_load_pressed() -> void:
	if not SaveData.load_game():
		return

	var request := MapLoadRequest.for_position(
		GameState.current_map_id,
		GameState.player_position,
		GameState.player_facing_direction
	)
	load_map(request)

func disable_debug_buttons() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
