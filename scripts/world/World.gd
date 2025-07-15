extends Node2D

# @onready var player = $Player
const PlayerScene = preload("res://scenes/player/player.tscn")
var current_map: Node = null

func load_map(scene: PackedScene, spawn_name: String = "") -> Node2D:
	if current_map:
		current_map.queue_free()

	await get_tree().process_frame
	current_map = scene.instantiate()
	var player = PlayerScene.instantiate()
	current_map.get_node("SortY").add_child(player)
	add_child(current_map)

	await get_tree().process_frame

	if spawn_name != "":
		var spawn = current_map.get_node_or_null(spawn_name)
		if spawn:
			player.global_position = spawn.global_position
			player.target_position = spawn.global_position.snapped(Vector2(16, 16))

	player.velocity = Vector2.ZERO
	player.hold_timer = 0.0
	player.is_moving = false
	
	return current_map

func _on_button_pressed() -> void:
	load_map(load("res://scenes/world/starting_town.tscn"), "StartingHouseSpawn")

func _on_battle_pressed() -> void:
	var encounteredPokemon = EncounterManager.load_pokemon("Masklit", 1)
	BattleManager.start_battle([encounteredPokemon], Vector2(0,0), Vector2(0,0), "")
