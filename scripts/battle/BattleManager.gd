extends Node
var wild_pokemon: Dictionary
var player_position: Vector2
var player_direction: Vector2
var current_map_path: String

func start_battle(wild_data: Dictionary, player_pos: Vector2, player_dir: Vector2, map_path: String):
	wild_pokemon = wild_data
	player_position = player_pos
	player_direction = player_dir
	current_map_path = map_path
	
	var world = get_parent().get_node("World")
	if(world == null):
		print("World not found")
		return
	world.queue_free() # remove battle scene
	await get_tree().process_frame
	var battle_scene = load("res://scenes/battles/battle.tscn").instantiate()
	get_parent().add_child(battle_scene)

func return_to_world():
	# Use a deferred call to make sure the current scene fully unloads first
	call_deferred("_load_previous_map")
	
func _load_previous_map():
	var battle = get_parent().get_node("Battle")
	if(battle == null):
		print("Battle not found")
	battle.queue_free() # remove battle scene
	await get_tree().process_frame
	var world_scene = load("res://scenes/world/world.tscn").instantiate()
	get_parent().add_child(world_scene)
	var current_map_scene = load(current_map_path)
	
	# Re-load the correct map
	world_scene.load_map(current_map_scene, "") 
	
	# Position the player after world has loaded
	var player = world_scene.get_node("Player")  
	player.global_position = player_position
	player.visuals.update_direction(player_direction)
	await get_tree().process_frame
	
