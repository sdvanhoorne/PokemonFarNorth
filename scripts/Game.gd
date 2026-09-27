class_name Game
extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/MainMenu.tscn")
const WORLD_SCENE := preload("res://scenes/World/World.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/Battle.tscn")

var active_scene: Node


func _ready() -> void:
	load_main_menu()

func load_main_menu() -> void:
	GameState.current_state = GameState.State.MAIN_MENU
	_change_scene(MAIN_MENU_SCENE)


func load_world() -> void:
	GameState.current_state = GameState.State.OVERWORLD
	_change_scene(WORLD_SCENE)

func start_battle(request: BattleStartRequest) -> void:
	# Capture anything we need in order to return to the world.
	var world := active_scene as World

	if world:
		world.capture_runtime_state()

	GameState.current_state = GameState.State.BATTLE

	var battle := _change_scene(BATTLE_SCENE)
	battle.start_battle(request)


func end_battle() -> void:
	GameState.current_state = GameState.State.OVERWORLD
	load_world()


func _change_scene(scene: PackedScene) -> Node:
	if is_instance_valid(active_scene):
		remove_child(active_scene)
		active_scene.queue_free()

	active_scene = scene.instantiate()
	add_child(active_scene)

	return active_scene
