class_name Game
extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/Battle.tscn")

var active_scene: Node


func _ready() -> void:
	await load_main_menu()


func load_main_menu() -> void:
	GameState.current_state = GameState.State.MAIN_MENU

	await _change_scene(MAIN_MENU_SCENE)


func load_world() -> void:
	GameState.current_state = GameState.State.OVERWORLD

	var world := await _change_scene(WORLD_SCENE) as World

	var request := MapLoadRequest.for_position(
		GameState.current_map_id,
		GameState.player_position,
		GameState.player_facing_direction
	)

	await world.load_map(request)


func start_battle(request: BattleStartRequest) -> void:
	# Capture the state required to rebuild the overworld after battle.
	var world := active_scene as World

	if world:
		world.capture_runtime_state()

	GameState.current_state = GameState.State.BATTLE

	var battle := await _change_scene(BATTLE_SCENE)

	battle.setup(
		request,
		PlayerInventory.PartyPokemon
	)

	# The battle UI is now available, so point DialogueManager at it.
	var message_box := battle.get_node_or_null(
		"BattleUI/BottomUI/MessageContainer"
	)

	if message_box:
		DialogueManager.message_box = message_box


func end_battle() -> void:
	await load_world()


func _change_scene(scene: PackedScene) -> Node:
	if is_instance_valid(active_scene):
		active_scene.queue_free()
		active_scene = null

		await get_tree().process_frame

	active_scene = scene.instantiate()
	add_child(active_scene)

	return active_scene
