# BattleController handles player input during battle
# and resolves events from the BattleEngine

extends Node2D
class_name BattleController

@onready var battle_ui: BattleUI = $BattleUI
var rng := RandomNumberGenerator.new()

var engine: BattleEngine
var state: Dictionary
var input_locked := false
var enemy_pokemon: Array[Pokemon]

func _ready() -> void:
	engine = BattleEngine.new()
	rng.randomize()
	_wire_signals()
	await _start_battle_intro()

func setup(enemy_party: Array, player_party: Array = []) -> void:
	if player_party.is_empty():
		player_party = PlayerInventory.PartyPokemon
	state = {
		"player_party": player_party.duplicate(),
		"enemy_party": enemy_party.duplicate(),
		"player_active": 0,
		"enemy_active": 0,
	}

func _wire_signals() -> void:
	$BattleUI/BattleOptionsUI/Fight.pressed.connect(_on_fight_pressed)
	$BattleUI/BattleOptionsUI/Run.pressed.connect(_on_run_pressed)
	$BattleUI/BattleOptionsUI/Switch.pressed.connect(_on_switch_pressed)
	$BattleUI/MovesBox/PokemonMoves/Move0.pressed.connect(Callable(self, "_on_move_pressed").bind(0))
	$BattleUI/MovesBox/PokemonMoves/Move1.pressed.connect(Callable(self, "_on_move_pressed").bind(1))
	$BattleUI/MovesBox/PokemonMoves/Move2.pressed.connect(Callable(self, "_on_move_pressed").bind(2))
	$BattleUI/MovesBox/PokemonMoves/Move3.pressed.connect(Callable(self, "_on_move_pressed").bind(3))

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

func _on_move_pressed(move_index: int) -> void:
	if input_locked: return
	input_locked = true
	await _process_turn(move_index)
	input_locked = false

func _process_turn(player_move_index: int) -> void:
	battle_ui.set_state(battle_ui.UIState.MESSAGE)

	var enemy_move_name := _determine_enemy_move_name()

	var result: Dictionary = engine.resolve_turn(state, player_move_index, enemy_move_name)
	state = result.state

	await _play_events(result.events)

	if _events_contain_battle_end(result.events):
		return

	battle_ui.set_state(BattleUI.UIState.OPTIONS)

func _determine_enemy_move_name() -> String:
	var enemy: Pokemon = _enemy_active()
	var enemy_moves: Array = enemy.get("move_names")
	if enemy_moves.is_empty():
		return enemy.moves[0].name
	return enemy_moves[rng.randi_range(0, enemy_moves.size() - 1)]

func _play_events(events: Array) -> void:
	for e in events:
		match e.type:
			"message":
				await DialogueManager.say(
					PackedStringArray([e.text]),
					{"lock_input": false, "require_input": false, "auto_advance_time": 1}
				)

			"hp_change":
				var target_is_player = (e.side == BattleEngine.Side.PLAYER)
				var target_pokemon: Pokemon
				if target_is_player:
					target_pokemon = _player_active() 
				else:
					target_pokemon = _enemy_active()

				var is_player_attacking = (e.side == BattleEngine.Side.ENEMY)
				battle_ui.update_health_bar(target_pokemon, is_player_attacking)

			"faint":
				await DialogueManager.say(
					PackedStringArray(["%s fainted" % e.name]),
					{"lock_input": false, "require_input": true}
				)

				if e.side == BattleEngine.Side.PLAYER:
					battle_ui.unload_player_pokemon()
					if state.player_party.size() > 0:
						battle_ui.load_player_pokemon(_player_active())
				else:
					battle_ui.unload_enemy_pokemon()
					if state.enemy_party.size() > 0:
						battle_ui.load_enemy_pokemon(_enemy_active())

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

func _player_active() -> Pokemon:
	return state.player_party[state.player_active]

func _enemy_active() -> Pokemon:
	return state.enemy_party[state.enemy_active]

func _end_battle_commit_and_return() -> void:
	PlayerInventory.PartyPokemon = state.player_party
	PlayerInventory.write_party()
	BattleManager.return_to_world()
