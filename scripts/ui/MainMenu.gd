extends Control


func _on_home_pressed() -> void:
	GameState.reset_run_state()
	GameState.world_entry = GameState.WorldEntry.NEW_GAME
	GameState.unlock_gameplay_input()

	var game := get_tree().current_scene as Game

	if game == null:
		push_error("MainMenu: Current scene is not Game")
		return

	await game.load_world()


func _on_battle_pressed() -> void:
	var encountered_pokemon := Pokemon.new_wild(14, 1)

	await BattleManager.start_wild_battle(
		[encountered_pokemon]
	)


func _on_load_pressed() -> void:
	if not SaveData.load_game():
		return

	GameState.world_entry = GameState.WorldEntry.LOAD_GAME
	GameState.unlock_gameplay_input()

	var game := get_tree().current_scene as Game

	if game == null:
		push_error("MainMenu: Current scene is not Game")
		return

	await game.load_world()


func _on_quit_pressed() -> void:
	get_tree().quit()
