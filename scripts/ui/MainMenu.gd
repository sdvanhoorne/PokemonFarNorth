extends Control

func _on_home_pressed() -> void:
	GameState.reset_run_state()
	GameState.world_entry = GameState.WorldEntry.NEW_GAME
	GameState.current_state = GameState.State.OVERWORLD
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_battle_pressed() -> void:
	var encounteredPokemon = Pokemon.new_wild(14, 1)
	BattleManager.start_wild_battle([encounteredPokemon])

func _on_load_pressed() -> void:
	if not SaveData.load_game():
		return
	GameState.world_entry = GameState.WorldEntry.LOAD_GAME
	GameState.unlock_gameplay_input()
	var game := get_tree().current_scene as Game
	game.load_world()

func _on_quit_pressed() -> void:
	get_tree().quit(0)
