extends Node2D

# @onready var player = $Player
const PlayerScene = preload("res://scenes/player/Player.tscn")
var current_map: Node = null
var is_loading_map := false

@onready var menu := $GameMenuCanvas
@onready var map_name_control: Control = $MapNameCanvas/MapName
var menu_open := false

func _ready() -> void:
	menu.visible = false
	DialogueManager.message_box = get_node_or_null("/root/World/CanvasLayer/MessageBox")

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if not menu_open and not GameState.gameplay_input_enabled:
			return

		_toggle_menu()
		get_viewport().set_input_as_handled()
		
func _toggle_menu() -> void:
	menu_open = not menu_open
	menu.visible = menu_open

	if menu_open:
		GameState.lock_gameplay_input()
		menu.open()
	else:
		menu.close()
		GameState.unlock_gameplay_input()

func load_map(map: PackedScene, player: Node2D, spawn_name := "", horizontal: bool = true, 
index: int = 0) -> Node2D:
	if is_loading_map:
		return current_map
	is_loading_map = true

	var new_map := map.instantiate()
	var old_map := current_map

	if player == null:
		player = PlayerScene.instantiate()
	else:
		var prev_parent := player.get_parent()
		if prev_parent:
			prev_parent.remove_child(player)

	current_map = new_map
	add_child(current_map)
	current_map.get_node("SortY").add_child(player)

	if spawn_name != "":
		var spawn := current_map.get_node("Spawns").get_node_or_null(spawn_name)
		if spawn:
			var base_pos : Vector2 = spawn.global_position.snapped(Vector2(GlobalConstants.tile_size, 
			GlobalConstants.tile_size))
			var offset : Vector2 = Vector2(index * GlobalConstants.tile_size, 
			0) if horizontal else Vector2(0, index * GlobalConstants.tile_size)
			player.global_position = base_pos + offset
			player.movement_controller.target_position = (base_pos + offset).snapped(Vector2(GlobalConstants.tile_size, 
			GlobalConstants.tile_size))

	player.movement_controller.is_moving = false
	player.movement_controller.facing_input = Vector2.ZERO
	player.movement_controller.sprinting = false
	player.movement_controller.hold_timer = 0.0
	
	if old_map:
		old_map.queue_free()

	is_loading_map = false
	
	# show area name card
	if new_map != null and new_map.has_method("get"):
		var map_display_name = new_map.get("map_display_name")
		map_name_control.show_map_name_card(map_display_name)
	
	return current_map

func _on_home_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	load_map(MapRegistry.get_map("starting_town"), null, 
	"StartingHouseSpawn")

func _on_battle_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	var encounteredPokemon = Pokemon.new_wild(14, 1)
	BattleManager.start_battle([encounteredPokemon], Vector2(0,0), Vector2(0,0), 
	"", false)
	
func _on_load_pressed() -> void:
	var save := SaveData.load_savedata()
	if save == null:
		return
	var scene_path = MapRegistry.MAPS[save.current_map_id]
	var scene = load(scene_path)
	load_map(scene, null, )

func disable_debug_buttons() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
