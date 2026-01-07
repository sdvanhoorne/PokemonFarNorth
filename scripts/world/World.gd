extends Node2D

# @onready var player = $Player
const PlayerScene = preload("res://scenes/player/player.tscn")
var current_map: Node = null
var is_loading_map := false

@onready var menu := $Menu
var menu_open := false

func _ready() -> void:
	menu.visible = false

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
			var base_pos : Vector2 = spawn.global_position.snapped(Vector2(GlobalConstants.TileSize, 
			GlobalConstants.TileSize))
			var offset : Vector2 = Vector2(index * GlobalConstants.TileSize, 
			0) if horizontal else Vector2(0, index * GlobalConstants.TileSize)
			player.global_position = base_pos + offset
			player.target_position = (base_pos + offset).snapped(Vector2(GlobalConstants.TileSize, 
			GlobalConstants.TileSize))

	player.is_moving = false
	player.facing_input = Vector2.ZERO
	player.sprinting = false
	player.hold_timer = 0.0
	player.velocity = Vector2.ZERO
	
	if old_map:
		old_map.queue_free()

	is_loading_map = false
	
	#not sure where this should go, just set the dialogue manager box every load map
	DialogueManager.message_box = get_node_or_null("/root/World/CanvasLayer/MessageBox")
	return current_map

func _on_home_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	load_map(load("res://scenes/world/towns/starting_town/starting_town.tscn"), null, 
	"StartingHouseSpawn")

func _on_battle_pressed() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
	var encounteredPokemon = Pokemon.new_wild(10, 1)
	BattleManager.start_battle([encounteredPokemon], Vector2(0,0), Vector2(0,0), 
	"res://scenes/world/towns/starting_town/starting_town.tscn")
	
func _on_load_pressed() -> void:
	var save := SaveData.load_savedata()
	if save == null:
		return
	var scene_path = MapRegistry.MAPS[save.current_map_id]
	var scene = load(scene_path)
	load_map(scene, null, )

func disable_debug_buttons() -> void:
	get_node_or_null("/root/World/DebugControls").visible = false
