extends Node2D

@onready var player = $Player
var current_map: Node = null

func load_map(scene: PackedScene, spawn_name: String = ""):
	if current_map:
		current_map.queue_free()

	current_map = scene.instantiate()
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

func _on_button_pressed() -> void:
	load_map(load("res://scenes/world/starting_town.tscn"), "StartingHouseSpawn")
