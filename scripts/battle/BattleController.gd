# BattleController handles player input during battle
# and resolves events from the BattleEngine

extends Node2D
class_name BattleController

@onready var battle_ui: BattleUI = $BattleUI
var rng := RandomNumberGenerator.new()
var session: BattleSession

var engine: BattleEngine
var state: Dictionary
var display_state: Dictionary
var input_locked := false
var enemy_pokemon: Array[Pokemon]
var pending_player_action: BattleAction = null
var pending_enemy_action: BattleAction = null

func _ready() -> void:
	engine = BattleEngine.new()
	engine.setup()
	rng.randomize()
	_wire_signals()

func setup(request: BattleStartRequest, player_party: Array[Pokemon]) -> void:
	session = BattleSession.from_request(request, player_party)
	await _start_battle_intro()

func _set_display_state_from_state() -> void:
	display_state = _deep_copy_state(state)

func _deep_copy_state(src: Dictionary) -> Dictionary:
	var dst: Dictionary = {}

	dst["player_active"] = src.get("player_active", 0)
	dst["enemy_active"] = src.get("enemy_active", 0)

	dst["player_party"] = _deep_copy_party(src.get("player_party", []))
	dst["enemy_party"] = _deep_copy_party(src.get("enemy_party", []))

	return dst

func _deep_copy_party(party: Array) -> Array[Pokemon]:
	var out: Array[Pokemon] = []
	out.resize(party.size())

	for i in party.size():
		var original := party[i] as Pokemon
		assert(original != null, "Party entry %d is null" % i)

		out[i] = original.clone(original.base_data.id)

	return out

func _wire_signals() -> void:
	$BattleUI/BottomUI/BattleOptionsUI/CenterContainer/Fight.pressed.connect(_on_fight_pressed)
	$BattleUI/BottomUI/BattleOptionsUI/CenterContainer4/Run.pressed.connect(_on_run_pressed)
	$BattleUI/BottomUI/BattleOptionsUI/CenterContainer2/Switch.pressed.connect(_on_switch_pressed)
	for b in get_tree().get_nodes_in_group("MoveButtons"):
		var btn := b as Button
		btn.pressed.connect(_on_move_pressed.bind(btn))
	battle_ui.party_ui.switch_requested.connect(_on_party_pokemon_chosen)

func _player_active_display() -> Pokemon:
	return display_state.player_party[display_state.player_active]

func _enemy_active_display() -> Pokemon:
	return display_state.enemy_party[display_state.enemy_active]

func _start_battle_intro() -> void:
	battle_ui.load_player_pokemon(session.get_active_player())
	battle_ui.load_enemy_pokemon(session.get_active_enemy())

	battle_ui.set_state(BattleUI.UIState.MESSAGE)
	# just say wild pokemon for now, add trainer dialogue later
	await DialogueManager.say(
		PackedStringArray(["A wild %s appeared!" % session.get_active_enemy().base_data.name]),
		{"lock_input": false, "require_input": true}
	)
	
	battle_ui.set_moves(session.get_active_player().move_names)
	battle_ui.set_state(BattleUI.UIState.OPTIONS)

func _on_fight_pressed() -> void:
	if input_locked: return
	battle_ui.set_state(BattleUI.UIState.MOVES)

func _on_run_pressed() -> void:
	pending_player_action = BattleAction.make_run(BattleDefinitions.BattleSide.PLAYER)
	await _process_turn()

func _run() -> void:
	if input_locked: return
	var result = BattleResult.run()
	
	battle_ui.set_state(BattleUI.UIState.MESSAGE)
	await DialogueManager.say(
		PackedStringArray(["You ran away..."]),
		{"lock_input": false, "require_input": true}
	)
	_finish_battle(result)

func _on_switch_pressed() -> void:
	if input_locked: return	
	battle_ui.set_state(BattleUI.UIState.PARTY)
	
func _on_party_pokemon_chosen(party_index: int) -> void:
	if input_locked: return
	input_locked = true
	pending_player_action = BattleAction.make_switch(BattleDefinitions.BattleSide.PLAYER, party_index)
	await _process_turn()
	input_locked = false

func _on_move_pressed(button: Button) -> void:
	if input_locked: return
	input_locked = true
	var move_index := int(button.name.trim_prefix("MoveButton"))
	pending_player_action = BattleAction.make_move(BattleDefinitions.BattleSide.PLAYER, move_index)
	await _process_turn()
	input_locked = false

func _process_turn():
	battle_ui.set_state(battle_ui.UIState.MESSAGE)
	
	if(pending_player_action.action == BattleDefinitions.BattleAction.RUN):
		_run()
	else:
		# no enemy switches yet, just moves
		# random move selection, no AI yet
		pending_enemy_action = BattleAction.make_move(BattleDefinitions.BattleSide.ENEMY, _determine_enemy_move_index())
		_set_display_state_from_state()
		
		var events: Array[BattleEvent] = engine.resolve_turn(session, pending_player_action, pending_enemy_action)
		await _play_events(events)
		if _events_contain_battle_end(events):
			return

		battle_ui.set_state(BattleUI.UIState.OPTIONS)

func _determine_enemy_move_index() -> int:
	return rng.randi_range(0, session.get_active_enemy().moves.size() - 1)
	
func _determine_enemy_move_name() -> String:
	var index = _determine_enemy_move_index()
	return session.get_active_enemy().moves[index].name

func _play_events(events: Array[BattleEvent]) -> void:
	for e in events:
		match e.event_type:
			BattleDefinitions.BattleEvent.MESSAGE:
				await DialogueManager.say(
					PackedStringArray([e.payload["text"]]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 1.0}
				)

			BattleDefinitions.BattleEvent.MOVE_USED:
				await DialogueManager.say(
					PackedStringArray([
						"%s used %s!" % [
							e.payload["user_name"],
							e.payload["move_name"]
						]
					]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 0.8}
				)

			BattleDefinitions.BattleEvent.MOVE_MISSED:
				await DialogueManager.say(
					PackedStringArray([
						"%s's %s missed!" % [
							e.payload["user_name"],
							e.payload["move_name"]
						]
					]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 0.8}
				)

			BattleDefinitions.BattleEvent.DAMAGE_APPLIED:
				# Optional: keep this if you want damage numbers or extra effects later.
				# For now, HP_CHANGED is probably the one that actually drives the UI bar.
				pass

			BattleDefinitions.BattleEvent.HP_CHANGED:
				var target_is_player := e.side == BattleDefinitions.BattleSide.PLAYER
				var current_hp: int = e.payload["current_hp"]
				var max_hp: int = e.payload["max_hp"]

				if target_is_player:
					battle_ui.update_health_bar(
						BattleDefinitions.BattleSide.PLAYER,
						current_hp,
						max_hp
					)
				else:
					battle_ui.update_health_bar(
						BattleDefinitions.BattleSide.ENEMY,
						current_hp,
						max_hp
					)

			BattleDefinitions.BattleEvent.STATUS_APPLIED:
				await DialogueManager.say(
					PackedStringArray([
						_status_applied_text(
							e.payload["pokemon_name"],
							e.payload["status_type"]
						)
					]),
					{"lock_input": false, "require_input": true}
				)

			BattleDefinitions.BattleEvent.FAINTED:
				await DialogueManager.say(
					PackedStringArray([
						"%s fainted!" % e.payload["pokemon_name"]
					]),
					{"lock_input": false, "require_input": true}
				)

				if e.side == BattleDefinitions.BattleSide.PLAYER:
					battle_ui.unload_player_pokemon()
				else:
					battle_ui.unload_enemy_pokemon()

			BattleDefinitions.BattleEvent.SWITCH_REQUIRED:
				if e.side == BattleDefinitions.BattleSide.PLAYER:
					battle_ui.set_state(BattleUI.UIState.PARTY)
					# If you support a forced-switch mode later, call that here instead.
					# Example:
					# battle_ui.show_party(session.player_party, true)
					return

			BattleDefinitions.BattleEvent.SWITCH_PERFORMED:
				var target_is_player := e.side == BattleDefinitions.BattleSide.PLAYER
				var new_index: int = e.payload["new_index"]

				if target_is_player:
					session.active_player_index = new_index
					battle_ui.unload_player_pokemon()
					battle_ui.load_player_pokemon(session.get_active_player())
					battle_ui.set_moves(session.get_active_player().move_names)
				else:
					session.active_enemy_index = new_index
					battle_ui.unload_enemy_pokemon()
					battle_ui.load_enemy_pokemon(session.get_active_enemy())

				await DialogueManager.say(
					PackedStringArray([
						"%s entered the battle!" % e.payload["new_pokemon_name"]
					]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 0.8}
				)

			BattleDefinitions.BattleEvent.XP_GAINED:
				await DialogueManager.say(
					PackedStringArray([
						"%s gained %s XP!" % [
							e.payload["pokemon_name"],
							e.payload["xp_gain_amount"]
						]
					]),
					{"lock_input": false, "require_input": true}
				)

			BattleDefinitions.BattleEvent.LEVEL_UP:
				await DialogueManager.say(
					PackedStringArray([
						"%s grew to level %s!" % [
							e.payload["pokemon_name"],
							e.payload["level"]
						]
					]),
					{"lock_input": false, "require_input": true}
				)

				# Optional: refresh the currently displayed player Pokémon info if needed
				if e.side == BattleDefinitions.BattleSide.PLAYER:
					battle_ui.load_player_pokemon(session.get_active_player())
					battle_ui.set_moves(session.get_active_player().move_names)

			BattleDefinitions.BattleEvent.RUN_SUCCEEDED:
				await DialogueManager.say(
					PackedStringArray(["Got away safely!"]),
					{"lock_input": false, "require_input": true}
				)

			BattleDefinitions.BattleEvent.RUN_FAILED:
				await DialogueManager.say(
					PackedStringArray([e.payload["reason"]]),
					{"lock_input": false, "require_input": true}
				)

			BattleDefinitions.BattleEvent.BATTLE_ENDED:
				_finish_battle(e)
				return

			_:
				pass

func _status_applied_text(pokemon_name: String, status_type: String) -> String:
	match status_type:
		"Poison":
			return "%s was poisoned!" % pokemon_name
		"Burn":
			return "%s was burned!" % pokemon_name
		"Sleep":
			return "%s fell asleep!" % pokemon_name
		"Paralysis":
			return "%s was paralyzed!" % pokemon_name
		"Freeze":
			return "%s was frozen solid!" % pokemon_name
		_:
			return "%s was afflicted with %s." % [pokemon_name, str(status_type)]

func _events_contain_battle_end(events: Array[BattleEvent]) -> bool:
	for e in events:
		if e.event_type == BattleDefinitions.BattleEvent.BATTLE_ENDED:
			return true
	return false

func _finish_battle(result: BattleEvent) -> void:
	PlayerInventory.PartyPokemon = session.player_party
	# handle other result info
	BattleManager.return_to_world(session.result)
