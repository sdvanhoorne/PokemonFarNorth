extends Node
var player_position: Vector2
var player_direction: Vector2
var current_map_path: String
var trainer_battle: bool = false

func start_battle(enemy_pokemon: Array[Pokemon], player_pos: Vector2, player_dir: Vector2, 
map_path: String, is_trainer: bool):
	# Store map information
	player_position = player_pos
	player_direction = player_dir
	current_map_path = map_path
	
	# is trainer or wild?
	trainer_battle = is_trainer
	
	# Remove world scene
	var world = get_parent().get_node("World")
	if(world == null):
		print("World not found")
		return
	world.queue_free()
	await get_tree().process_frame
	
	# Create battle scene
	var battle_scene = load("res://scenes/battles/battle.tscn").instantiate()
	battle_scene.setup(enemy_pokemon, PlayerInventory.PartyPokemon)
	battle_scene.print_tree_pretty()
	var message_box = battle_scene.get_node_or_null("BattleUI/MessageBox")
	DialogueManager.message_box = message_box
	battle_scene.enemy_pokemon = enemy_pokemon
	get_parent().add_child(battle_scene)

func return_to_world():
	# Use a deferred call to make sure the current scene fully unloads first
	call_deferred("_load_previous_map")
	
func _load_previous_map():
	# Remove battle scene
	get_node("/root").print_tree_pretty()
	var battle = get_parent().get_node("Battle")
	if(battle == null):
		print("Battle not found")
	battle.queue_free()
	await get_tree().process_frame
	
	#i suspect we will need to store the world node somewhere
	# between sessions and events like battles
	
	# Load current map scene
	var world_scene = load("res://scenes/world/world.tscn").instantiate()
	get_parent().add_child(world_scene)
	var current_map_scene = load(current_map_path)
	var current_map = await world_scene.load_map(current_map_scene, null, "") 
	
	# Re-position the player after world has loaded
	var player = current_map.get_node("SortY").get_node("Player")  
	player.global_position = player_position
	await get_tree().process_frame
	player.facing_input = player_direction
	player.update_facing_direction()
