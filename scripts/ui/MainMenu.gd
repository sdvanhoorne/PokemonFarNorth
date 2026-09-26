extends Control

# NEED TO MAKE A NEW MAP LOADER TO HANDLE LOADING MAP FROM CONTINUE/NEW GAME 
# AND ALSO FOR WORLD TO TRANSITION BETWEEN MAPS

func _on_home_pressed() -> void:
	var request := MapLoadRequest.for_spawn("starting_town", "StartingHouseSpawn", "down")
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_battle_pressed() -> void:
	var encounteredPokemon = Pokemon.new_wild(14, 1)
	BattleManager.start_wild_battle([encounteredPokemon], Vector2(0, 0), "down")

func _on_load_pressed() -> void:
	if not SaveData.load_game():
		return

	var request := MapLoadRequest.for_position(
		GameState.current_map_id,
		GameState.player_position,
		GameState.player_facing_direction
	)
	
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit(0)
