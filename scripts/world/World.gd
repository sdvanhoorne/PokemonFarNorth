extends Node2D

# @onready var player = $Player
const PlayerScene = preload("res://scenes/player/player.tscn")
var current_map: Node = null
var is_loading_map := false

func load_map(map: PackedScene, player: Node2D, spawn_name := "") -> Node2D:
	if is_loading_map:
		return current_map
	is_loading_map = true

	var new_map := map.instantiate()
	var old_map := current_map

	# Detach or instantiate the player
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
		var spawn := current_map.get_node_or_null(spawn_name)
		if spawn:
			player.global_position = spawn.global_position
			player.target_position = spawn.global_position.snapped(Vector2(16, 16))

	if old_map:
		old_map.queue_free()

	is_loading_map = false
	return current_map

func _on_button_pressed() -> void:
	load_map(load("res://scenes/world/starting_town.tscn"), null, "StartingHouseSpawn")

func _on_battle_pressed() -> void:
	var encounteredPokemon = Pokemon.new_wild(10, 1)
	BattleManager.start_battle([encounteredPokemon], Vector2(0,0), Vector2(0,0), "res://scenes/world/starting_town.tscn")
