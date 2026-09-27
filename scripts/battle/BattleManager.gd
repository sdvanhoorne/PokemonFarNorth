extends Node

var current_request: BattleStartRequest = null


func start_battle(request: BattleStartRequest) -> void:
	current_request = request

	var game := get_tree().current_scene as Game

	if game == null:
		push_error("BattleManager: Current scene is not Game")
		return

	await game.start_battle(request)


func start_wild_battle(
	enemy_party: Array[Pokemon],
	_intro_lines: PackedStringArray = PackedStringArray()
) -> void:
	var request := BattleStartRequest.for_wild_battle(
		enemy_party
	)

	await start_battle(request)


func start_trainer_battle(
	enemy_party: Array[Pokemon],
	trainer_data: BattleTrainerData
) -> void:
	var request := BattleStartRequest.for_trainer_battle(
		enemy_party,
		trainer_data
	)

	await start_battle(request)


func return_to_overworld(result: BattleResult = null) -> void:
	if current_request == null:
		push_warning(
			"BattleManager.return_to_overworld: current_request was null"
		)
		return

	_apply_battle_result(result)

	current_request = null

	var game := get_tree().current_scene as Game

	if game == null:
		push_error("BattleManager: Current scene is not Game")
		return

	await game.end_battle()


func _apply_battle_result(result: BattleResult) -> void:
	if result == null:
		return

	if result.updated_party.size() > 0:
		PlayerInventory.PartyPokemon = result.updated_party.duplicate(true)

	match result.outcome:
		BattleDefinitions.BattleOutcome.TRAINER_WIN:
			if result.defeated_trainer_id != "":
				GameState.mark_trainer_defeated(
					result.defeated_trainer_id
				)

		BattleDefinitions.BattleOutcome.CAPTURE:
			pass

		BattleDefinitions.BattleOutcome.TRAINER_LOSE:
			# Later: return to last heal point.
			pass

		BattleDefinitions.BattleOutcome.WILD_LOSE:
			# Later: return to last heal point.
			pass
