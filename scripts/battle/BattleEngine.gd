# BattleEngine handles battle logic
# updates Pokemon objects
# and queues events for the BattleController

extends Node
class_name BattleEngine

const DamageCalculation := preload("res://scripts/battle/DamageCalculation.gd")
var damage_calculation: DamageCalculation

func setup() -> void:
	damage_calculation = DamageCalculation.new()

func resolve_turn(session: BattleSession, player_action: BattleAction, enemy_action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var ordered_actions := _get_ordered_actions(session, player_action, enemy_action)

	for action in ordered_actions:
		if session.is_over():
			break

		var user := _get_action_user(session, action)
		if user == null or user.current_hp <= 0:
			continue

		events.append_array(_resolve_action(session, action))

		if _handle_post_action_state(session, events):
			break

	return events

func _resolve_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	match action.action:
		BattleDefinitions.BattleAction.MOVE:
			return _resolve_move_action(session, action)
		BattleDefinitions.BattleAction.SWITCH:
			return _resolve_switch_action(session, action)
		#BattleDefinitions.BattleAction.RUN:
		#	return _resolve_run_action(session, action)
		#BattleDefinitions.BattleAction.ITEM:
		#	return _resolve_item_action(session, action)
	return []

# Resolve moves
func _resolve_move_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var user := _get_action_user(session, action)
	var opponent := _get_action_target(session, action)

	if user == null or opponent == null:
		return events

	if action.move_index < 0 or action.move_index >= user.moves.size():
		return events

	var move: Move = user.moves[action.move_index]
	if move == null:
		return events

	events.append(BattleEvent.move_used(
		action.actor,
		user.base_data.name,
		move.name
	))

	match move.category:
		"Physical", "Special":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_damage_move(action.actor, move, user, target))

		"Status":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_status_move(action.actor, move, user, target))

		"StatChange":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_stat_change_move(action.actor, move, user, target))

		_:
			events.append(BattleEvent.message("But it failed."))

	return events
	
func _resolve_damage_move(attacker_side: BattleDefinitions.BattleSide, move: Move, attacker: Pokemon, defender: Pokemon) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	if attacker == null or defender == null:
		return events

	if attacker.current_hp <= 0:
		return events

	var old_hp = defender.current_hp
	var damage: int = damage_calculation.get_damage(move, attacker, defender)
	defender.current_hp = max(defender.current_hp - damage, 0)

	var defender_side := BattleDefinitions.BattleSide.ENEMY
	if attacker_side == BattleDefinitions.BattleSide.ENEMY:
		defender_side = BattleDefinitions.BattleSide.PLAYER

	events.append(BattleEvent.hp_changed(
		defender_side,
		defender.base_data.name,
		old_hp,
		defender.current_hp,
		defender.battle_stats.hp
	))

	return events

func _resolve_status_move(attacker_side: BattleDefinitions.BattleSide, move: Move, user: Pokemon, target: Pokemon) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var status = move.status
	target.status = status
	events.append(BattleEvent.status_applied(status))
	return events

func _resolve_stat_change_move(attacker_side: BattleDefinitions.BattleSide, move: Move, user: Pokemon, target: Pokemon) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var stat_name: String = move.target_stat
	var current_value = target.battle_stats.get(stat_name)
	target.battle_stats.set(stat_name, current_value * move.stat_multiplier)

	var target_side := attacker_side
	if target != user:
		target_side = _opposing_side(attacker_side)

	if move.stat_multiplier > 1.0:
		events.append(BattleEvent.message("%s's %s rose." % [target.base_data.name, stat_name]))
	elif move.stat_multiplier < 1.0:
		events.append(BattleEvent.message("%s's %s fell." % [target.base_data.name, stat_name]))
	else:
		events.append(BattleEvent.message("Nothing happened."))

	return events

# Resolve switch
func _resolve_switch_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var old_pokemon_name: String
	var new_pokemon_name: String
	if(action.actor == BattleDefinitions.BattleSide.PLAYER):
		old_pokemon_name = session.get_active_player().base_data.name
		session.switch_player_to(action.switch_index)
		new_pokemon_name = session.get_active_player().base_data.name
	else:
		old_pokemon_name = session.get_active_enemy().base_data.name
		session.switch_enemy_to(action.switch_index)
		new_pokemon_name = session.get_active_enemy().base_data.name
	events.append(BattleEvent.switch_performed(action.actor, old_pokemon_name, new_pokemon_name, action.switch_index))
	return events

# Speed/priority handling
func _get_ordered_actions(session: BattleSession, player_action: BattleAction, enemy_action: BattleAction) -> Array[BattleAction]:
	var actions: Array[BattleAction] = [player_action, enemy_action]

	actions.sort_custom(func(a: BattleAction, b: BattleAction) -> bool:
		var a_priority := _get_action_priority(session, a)
		var b_priority := _get_action_priority(session, b)

		if a_priority != b_priority:
			return a_priority > b_priority

		var a_speed := _get_action_speed(session, a)
		var b_speed := _get_action_speed(session, b)

		if a_speed != b_speed:
			return a_speed > b_speed

		return randf() < 0.5
	)

	return actions

func _get_action_speed(session: BattleSession, action: BattleAction) -> int:
	var user := _get_action_user(session, action)
	if user == null:
		return 0
	return user.battle_stats.speed

func _get_action_priority(session: BattleSession, action: BattleAction) -> int:
	# implement move priority later
	return 1

# Helpers and other
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

func _opposing_side(side: BattleDefinitions.BattleSide) -> BattleDefinitions.BattleSide:
	if side == BattleDefinitions.BattleSide.PLAYER:
		return BattleDefinitions.BattleSide.ENEMY
	else:
		return BattleDefinitions.BattleSide.PLAYER

func _get_action_user(session: BattleSession, action: BattleAction) -> Pokemon:
	match action.actor:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_player()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_enemy()
	return null
	
func _get_action_target(session: BattleSession, action: BattleAction) -> Pokemon:
	match action.actor:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_enemy()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_player()
	return null

func _get_move_target(move: Move, user: Pokemon, opponent: Pokemon) -> Pokemon:
	match move.target:
		"Self":
			return user
		"Enemy":
			return opponent
	return opponent

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
