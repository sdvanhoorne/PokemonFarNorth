extends Node

var current_request: BattleStartRequest = null

func start_battle(request: BattleStartRequest) -> void:
	current_request = request

	var world := get_parent().get_node_or_null("World")
	if world == null:
		push_warning("BattleManager.start_battle: World not found")
		return

	world.queue_free()
	await get_tree().process_frame

	var battle_scene = load("res://scenes/battles/Battle.tscn").instantiate()
	get_parent().add_child(battle_scene)

	# BattleController / battle scene should take the request and build the session.
	if battle_scene.has_method("setup"):
		battle_scene.setup(request, PlayerInventory.PartyPokemon)

	# Point DialogueManager at the battle message box if present.
	var message_box = battle_scene.get_node_or_null("BattleUI/BottomUI/MessageContainer")
	if message_box != null:
		DialogueManager.message_box = message_box


# Temporary migration helper for wild battles.
func start_wild_battle(
	enemy_party: Array[Pokemon],
	player_position: Vector2,
	player_direction: String,
	intro_lines: PackedStringArray = PackedStringArray()
) -> void:
	var request := BattleStartRequest.for_wild_battle(
		enemy_party,
		player_position,
		player_direction
		)
	await start_battle(request)


# Temporary migration helper for trainer battles.
func start_trainer_battle(
	enemy_party: Array[Pokemon],
	player_position: Vector2,
	player_direction: String,
	trainer_data: BattleTrainerData
) -> void:
	var request := BattleStartRequest.for_trainer_battle(
		enemy_party,
		player_position,
		player_direction,
		trainer_data
	)
	await start_battle(request)


func return_to_world(result: BattleResult = null) -> void:
	call_deferred("_load_previous_map", result)

func _load_previous_map(result: BattleResult = null) -> void:
	var battle := get_parent().get_node_or_null("Battle")
	if battle == null:
		push_warning("BattleManager._load_previous_map: Battle scene not found")
	else:
		battle.queue_free()
		await get_tree().process_frame

	if current_request == null:
		push_warning("BattleManager._load_previous_map: current_request was null")
		return

	_apply_battle_result(result)

	var world_scene = load("res://scenes/world/world.tscn").instantiate()
	get_parent().add_child(world_scene)

	var request := MapLoadRequest.for_position(
		GameState.current_map_id,
		current_request.player_position,
		current_request.player_direction
	)

	await world_scene.load_map(request)

func _apply_battle_result(result: BattleResult) -> void:
	if result == null:
		return

	if result.updated_party.size() > 0:
		PlayerInventory.PartyPokemon = result.updated_party.duplicate(true)

	match result.outcome:
		BattleDefinitions.BattleOutcome.TRAINER_WIN:
			if result.defeated_trainer_id != "":
				GameState.mark_trainer_defeated(result.defeated_trainer_id)

		BattleDefinitions.BattleOutcome.CAPTURE:
			# If capture already modified PlayerInventory during battle, the updated_party
			# assignment above is enough. If not, do it here.
			pass

		BattleDefinitions.BattleOutcome.TRAINER_LOSE:
			# Later: teleport to last heal point instead of returning to battle origin.
			pass

		BattleDefinitions.BattleOutcome.WILD_LOSE:
			# Same as above eventually.
			pass
