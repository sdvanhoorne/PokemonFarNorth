# BattleEngine handles battle logic
# updates Pokemon objects
# and queues events for the BattleController

extends Node
class_name BattleEngine

const DamageCalculation := preload("res://scripts/battle/DamageCalculation.gd")
var damage_calculation: DamageCalculation

func setup() -> void:
	damage_calculation = DamageCalculation.new()
	# result: "player_win" / "player_lose" / "fled" etc
	return {"type": "battle_end", "result": result}

func _handle_post_action_state(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var enemy_pokemon := session.get_active_enemy()
	if enemy_pokemon.current_hp <= 0:
		return _handle_enemy_fainted(session, events)

	var player_pokemon := session.get_active_player()
	if player_pokemon.current_hp <= 0:
		return _handle_player_fainted(session, events)

	return false
	
func _handle_enemy_fainted(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var fainted_enemy := session.get_active_enemy()
	events.append(BattleEvent.fainted(BattleDefinitions.BattleSide.ENEMY, fainted_enemy.base_data.name))

	_award_xp_for_enemy_faint(session, fainted_enemy, events)

	if not session.has_usable_enemy_pokemon():
		_set_battle_result(session, BattleDefinitions.BattleOutcome.WIN)
		events.append(BattleEvent.battle_ended(session.result))
		return true

	var next_index := _find_next_usable_enemy_index(session)
	if next_index == -1:
		_set_battle_result(session, BattleDefinitions.BattleOutcome.WIN)
		events.append(BattleEvent.battle_ended(session.result))
		return true

	var old_name := fainted_enemy.base_data.name
	session.switch_enemy_to(next_index)
	var next_enemy := session.get_active_enemy()

	events.append(BattleEvent.switch_performed(
		BattleDefinitions.BattleSide.ENEMY,
		old_name,
		next_enemy.base_data.name,
		next_index
	))
	events.append(BattleEvent.message("%s was sent out!" % next_enemy.base_data.name))
	return true

func _handle_player_fainted(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var fainted_player := session.get_active_player()
	events.append(BattleEvent.fainted(BattleDefinitions.BattleSide.PLAYER, fainted_player.base_data.name))

	if not session.has_usable_player_pokemon():
		_set_battle_result(session, BattleDefinitions.BattleOutcome.LOSE)
		events.append(BattleEvent.battle_ended(session.result))
		return true

	events.append(BattleEvent.message("Choose your next Pokémon."))
	events.append(BattleEvent.player_switch_required())
	return true

func _award_xp_for_enemy_faint(session: BattleSession, fainted_enemy: Pokemon, events: Array[BattleEvent]) -> void:
	var active_player := session.get_active_player()
	var xp_gain_amount: int = fainted_enemy.calculate_xp_given()

	active_player.add_xp(xp_gain_amount)
	events.append(BattleEvent.xp_gained(
		active_player.base_data.name,
		xp_gain_amount
	))

	while active_player.leveled_up():
		events.append(BattleEvent.level_up(
			active_player.base_data.name,
			active_player.level
		))

func _set_battle_result(session: BattleSession, outcome: BattleDefinitions.BattleOutcome) -> void:
	var result := BattleResult.new()
	result.battle_type = session.battle_type
	result.outcome = outcome
	session.result = result

func resolve_turn(session: BattleSession, player_action: BattleAction, enemy_action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	
	var player_pokemon: Pokemon = session.get_active_player()
	var enemy_pokemon: Pokemon = session.get_active_enemy()
	
	
	return events

func resolve_turn(player_action: BattleAction, enemy_action: BattleAction, state: Dictionary):
	var events: Array = []
	
	var player_pokemon: Pokemon = _player_active(state)
	var enemy_pokemon: Pokemon = _enemy_active(state)
	
	# determine first side to go via speed
	var first_side: int = BattleDefinitions.BattleSide.PLAYER if player_pokemon.battle_stats.speed >= enemy_pokemon.battle_stats.speed else BattleDefinitions.BattleSide.ENEMY
	var second_side: int = BattleDefinitions.BattleSide.ENEMY if first_side == BattleDefinitions.BattleSide.PLAYER else BattleDefinitions.BattleSide.PLAYER
	
	# if player faster
	if(first_side == BattleDefinitions.BattleSide.PLAYER):
	# player switch
		if(player_action.action == BattleDefinitions.BattleAction.SWITCH):
			events.append(switch(BattleDefinitions.BattleSide.PLAYER, player_action.switch_index))
			events.append(msg("You sent out %s" % [PlayerInventory.PartyPokemon[player_action.switch_index].base_data.name]))
			player_pokemon = _execute_switch(BattleDefinitions.BattleSide.PLAYER, player_action.switch_index, state)
	# enemy switch
		if(enemy_action.action == BattleDefinitions.BattleAction.SWITCH):
			events.append(switch(BattleDefinitions.BattleSide.ENEMY, enemy_action.switch_index))
			events.append(msg("Opponent sent out %s" % [state.enemy_party[enemy_action.switch_index].base_data.name]))
			enemy_pokemon = _execute_switch(BattleDefinitions.BattleSide.ENEMY, enemy_action.switch_index, state)
	# player move
		if(player_action.action == BattleDefinitions.BattleAction.MOVE):
			var player_move: Move = player_pokemon.moves[player_action.move_index]
			_execute_move(BattleDefinitions.BattleSide.PLAYER, player_pokemon, enemy_pokemon, player_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	# enemy move
		if(enemy_action.action == BattleDefinitions.BattleAction.MOVE):
			var enemy_move: Move = enemy_pokemon.moves[enemy_action.move_index]
			_execute_move(BattleDefinitions.BattleSide.ENEMY, enemy_pokemon, player_pokemon, enemy_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}

	# if enemy faster
	else:
	# enemy switch
		if(enemy_action.action_type == BattleDefinitions.BattleAction.SWITCH):
			events.append(switch(BattleDefinitions.BattleSide.ENEMY, enemy_action.switch_index))
			events.append(msg("Opponent sent out %s" % [state.enemy_party[enemy_action.switch_index].base_data.name]))
			enemy_pokemon = _execute_switch(BattleDefinitions.BattleSide.ENEMY, enemy_action.switch_index, state)
	# player switch
		if(player_action.action_type == BattleDefinitions.BattleAction.SWITCH):
			events.append(switch(BattleDefinitions.BattleSide.PLAYER, player_action.switch_index))
			events.append(msg("You sent out %s" % [PlayerInventory.PartyPokemon[player_action.switch_index].base_data.name]))
			player_pokemon = _execute_switch(BattleDefinitions.BattleSide.PLAYER, player_action.switch_index, state)
	# enemy move
		if(enemy_action.action_type == BattleDefinitions.BattleAction.MOVE):
			var enemy_move: Move = enemy_pokemon.moves[enemy_action.move_index]
			_execute_move(BattleDefinitions.BattleSide.ENEMY, enemy_pokemon, player_pokemon, enemy_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	# player move
		if(player_action.action_type == BattleDefinitions.BattleAction.MOVE):
			var player_move: Move = player_pokemon.moves[player_action.move_index]
			_execute_move(BattleDefinitions.BattleSide.PLAYER, player_pokemon, enemy_pokemon, player_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	
	return {"state": state, "events": events}

func _execute_switch(side: int, switch_index: int, state: Dictionary) -> Pokemon:
	if(side == BattleDefinitions.BattleSide.PLAYER):
		state.player_active = switch_index
		return _player_active(state)
	else:
		state.enemy_active = switch_index
		return _enemy_active(state)

func _execute_move(side: int, attacker: Pokemon, defender: Pokemon, move: Move, events: Array) -> void:
	# If attacker already fainted (possible later add recoil/end-of-turn etc)
	if attacker.current_hp <= 0:
		return

	events.append(msg("%s used %s" % [attacker.base_data.name, move.name]))

	match move.category:
		"Physical", "Special":
			_apply_damage(side, move, attacker, defender, events)
		"Status":
			_apply_status(move, attacker, defender, events)
		"StatChange":
			_apply_stat_change(move, attacker, defender, events)
		_:
			events.append(msg("But it failed."))

func _apply_damage(attacker_side: int, move: Move, attacker: Pokemon, defender: Pokemon, events: Array) -> void:
	var damage: int = damage_calculation.get_damage(move, attacker, defender)
	var old_hp = defender.current_hp
	var new_hp = max(defender.current_hp - damage, 0)
	defender.current_hp -= damage
	var defender_side: int = BattleDefinitions.BattleSide.ENEMY if attacker_side == BattleDefinitions.BattleSide.PLAYER else BattleDefinitions.BattleSide.PLAYER
	events.append(BattleEvent.hp_changed(defender_side, defender.base_data.name, old_hp, defender.current_hp, defender.base_data.base_stats.hp))

func _apply_status(move: Move, attacker: Pokemon, defender: Pokemon, events: Array) -> void:
	var status_type = move.status
	if move.target == "Self":
		attacker.status = status_type
		events.append(msg("%s is now %s." % [attacker.base_data.name, str(status_type)]))
	elif move.target == "Enemy":
		defender.status = status_type
		events.append(msg("%s is now %s." % [defender.base_data.name, str(status_type)]))

func _apply_stat_change(move: Move, attacker: Pokemon, defender: Pokemon, events: Array) -> void:
	var target: Pokemon = attacker if move.target == "Self" else defender
	var name := target.base_data.name

	# replace with stat stages later
	var stat_name: String = move.target_stat
	var current_value = target.battle_stats.get(stat_name)
	target.battle_stats.set(stat_name, current_value * move.stat_multiplier)

	var went_up = move.stat_multiplier > 1.0
	var went_down = move.stat_multiplier < 1.0
	if went_up:
		events.append(msg("%s's %s rose." % [name, stat_name]))
	elif went_down:
		events.append(msg("%s's %s fell." % [name, stat_name]))
	else:
		events.append(msg("Nothing happened."))

func _find_next_usable_enemy_index(session: BattleSession) -> int:
	for i in range(session.enemy_party.size()):
		if i == session.active_enemy_index:
			continue
		var pokemon: Pokemon = session.enemy_party[i]
		if pokemon.current_hp > 0:
			return i
	return -1
	
func _find_next_usable_player_index(session: BattleSession) -> int:
	for i in range(session.player_party.size()):
		if i == session.active_player_index:
			continue
		var pokemon: Pokemon = session.player_party[i]
		if pokemon.current_hp > 0:
			return i
	return -1
