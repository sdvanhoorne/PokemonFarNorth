extends Control

func _on_home_pressed() -> void:
	GameState.reset_run_state()
	GameState.world_entry = GameState.WorldEntry.NEW_GAME
	GameState.current_state = GameState.State.OVERWORLD
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_battle_pressed() -> void:
	var encounteredPokemon = Pokemon.new_wild(14, 1)
	BattleManager.start_wild_battle([encounteredPokemon], Vector2(0, 0), "down")

func _on_load_pressed() -> void:
	if not SaveData.load_game():
		return
	GameState.world_entry = GameState.WorldEntry.LOAD_GAME
	GameState.current_state = GameState.State.OVERWORLD
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit(0)
