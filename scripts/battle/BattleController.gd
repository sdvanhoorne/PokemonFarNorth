# BattleController handles player input during battle
# and resolves events from the BattleEngine

extends Node2D
class_name BattleController

@onready var battle_ui: BattleUI = $BattleUI
var rng := RandomNumberGenerator.new()

var engine: BattleEngine
var state: Dictionary
var display_state: Dictionary
var input_locked := false
var enemy_pokemon: Array[Pokemon]
var pending_player_action: BattleAction = null
var pending_enemy_action: BattleAction = null

func _ready() -> void:
	engine = BattleEngine.new()
	rng.randomize()
	_wire_signals()
	await _start_battle_intro()

func setup(enemy_party: Array, player_party: Array = []) -> void:
	if player_party.is_empty():
		player_party = PlayerInventory.PartyPokemon
	state = {
		"player_party": player_party.duplicate(true),
		"enemy_party": enemy_party.duplicate(true),
		"player_active": 0,
		"enemy_active": 0,
	}

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
	$BattleUI/BottomUI/BattleOptionsUI/Fight.pressed.connect(_on_fight_pressed)
	$BattleUI/BottomUI/BattleOptionsUI/Run.pressed.connect(_on_run_pressed)
	$BattleUI/BottomUI/BattleOptionsUI/Switch.pressed.connect(_on_switch_pressed)
	for b in get_tree().get_nodes_in_group("MoveButtons"):
		var btn := b as Button
		btn.pressed.connect(_on_move_pressed.bind(btn))
	battle_ui.party_ui.switch_requested.connect(_on_party_pokemon_chosen)
	
func _player_active() -> Pokemon:
	return state.player_party[state.player_active]
	
func _player_active_display() -> Pokemon:
	return display_state.player_party[display_state.player_active]

func _enemy_active() -> Pokemon:
	return state.enemy_party[state.enemy_active]
	
func _enemy_active_display() -> Pokemon:
	return display_state.enemy_party[display_state.enemy_active]

func _start_battle_intro() -> void:
	battle_ui.load_player_pokemon(_player_active())
	battle_ui.load_enemy_pokemon(_enemy_active())

	battle_ui.set_state(BattleUI.UIState.MESSAGE)
	# just say wild pokemon for now, add trainer dialogue later
	await DialogueManager.say(
		PackedStringArray(["A wild %s appeared!" % _enemy_active().base_data.name]),
		{"lock_input": false, "require_input": true}
	)
	
	battle_ui.set_moves(_player_active().move_names)
	battle_ui.set_state(BattleUI.UIState.OPTIONS)

func _on_fight_pressed() -> void:
	if input_locked: return
	battle_ui.set_state(BattleUI.UIState.MOVES)

func _on_run_pressed() -> void:
	pending_player_action = BattleAction.make_run("player")

func _run() -> void:
	if input_locked: return
	
	battle_ui.set_state(BattleUI.UIState.MESSAGE)
	await DialogueManager.say(
		PackedStringArray(["You ran away..."]),
		{"lock_input": false, "require_input": true}
	)
	_end_battle_commit_and_return()

func _on_switch_pressed() -> void:
	if input_locked: return	
	battle_ui.set_state(BattleUI.UIState.PARTY)
	
func _on_party_pokemon_chosen(party_index: int) -> void:
	if input_locked: return
	input_locked = true
	pending_player_action = BattleAction.make_switch("player", party_index)
	await _process_turn()
	input_locked = false

func _on_move_pressed(button: Button) -> void:
	if input_locked: return
	input_locked = true
	var move_index := int(button.name.trim_prefix("MoveButton"))
	pending_player_action = BattleAction.make_move("player", move_index)
	await _process_turn()
	input_locked = false

func _process_turn():
	battle_ui.set_state(battle_ui.UIState.MESSAGE)
	
	if(pending_player_action.action_type == BattleAction.battle_action_type.RUN):
		_run()
		
	# no enemy switches yet, just moves
	pending_enemy_action = BattleAction.make_move("enemy", _determine_enemy_move_index())
	_set_display_state_from_state()
		
	var result: Dictionary = engine.resolve_turn(pending_player_action, pending_enemy_action, state)
	state = result.state
	await _play_events(result.events)
	if _events_contain_battle_end(result.events):
		return

	battle_ui.set_state(BattleUI.UIState.OPTIONS)

func _determine_enemy_move_index() -> int:
	return rng.randi_range(0, _enemy_active().moves.size() - 1)
	
func _determine_enemy_move_name() -> String:
	var index = _determine_enemy_move_index()
	return _enemy_active().moves[index].name

func _play_events(events: Array) -> void:
	for e in events:
		match e.type:
			"message":
				await DialogueManager.say(
					PackedStringArray([e.text]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 1}
				)
				
			"switch":
				# some redundant code with hp change
				var target_is_player = (e.side == BattleEngine.Side.PLAYER)
				if target_is_player:
					display_state.player_active = e.switch_index
					battle_ui.unload_player_pokemon()
					battle_ui.load_player_pokemon(_player_active_display())
					battle_ui.set_moves(_player_active_display().move_names)
				else:
					display_state.enemy_active = e.switch_index
					battle_ui.unload_enemy_pokemon()
					battle_ui.load_enemy_pokemon(_enemy_active_display())
					
			"hp_change":
				var target_is_player = (e.side == BattleEngine.Side.PLAYER)
				var target_pokemon: Pokemon
				if target_is_player:
					target_pokemon = _player_active_display() 
				else:
					target_pokemon = _enemy_active_display()

				var is_player_attacking = (e.side == BattleEngine.Side.ENEMY)
				target_pokemon.current_hp -= e.damage
				battle_ui.update_health_bar(target_pokemon, is_player_attacking)

			"faint":
				await DialogueManager.say(
					PackedStringArray(["%s fainted" % e.name]),
					{"lock_input": false, "require_input": true}
				)

				if e.side == BattleEngine.Side.PLAYER:
					battle_ui.unload_player_pokemon()
				else:
					battle_ui.unload_enemy_pokemon()

			"xp_gain":
				# animate xp bar gain
				await DialogueManager.say(
					PackedStringArray(["%s gained %s xp" % [e.name, e.amount]]),
					{"lock_input": false, "require_input": true}
				)
				
			"level_up":
				# refresh pokemon level in UI
				# show stat gains?
				# refresh active pokemon moves in case they learned a new one
				await DialogueManager.say(
					PackedStringArray(["%s leveled up to level %s" % [e.name, e.level]]),
					{"lock_input": false, "require_input": true}
				)
				pass

			"battle_end":
				_end_battle_commit_and_return()
				return

			_:
				pass

func _events_contain_battle_end(events: Array) -> bool:
	for e in events:
		if e.type == "battle_end":
			return true
	return false

func _end_battle_commit_and_return() -> void:
	PlayerInventory.PartyPokemon = state.player_party
	PlayerInventory.write_party()
	BattleManager.return_to_world()
