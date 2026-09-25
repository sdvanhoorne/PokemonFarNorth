# BattleEngine handles battle logic
# updates Pokemon objects
# and queues events for the BattleController

extends Node
class_name BattleEngine

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
		if user == null or user.pokemon.current_hp <= 0:
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

func _resolve_move_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var user := _get_action_user(session, action)
	var opponent := _get_action_target(session, action)

	if user == null or opponent == null:
		return events

	if action.move_index < 0 or action.move_index >= user.pokemon.moves.size():
		return events

	var move: Move = user.pokemon.moves[action.move_index]
	if move == null:
		return events

	events.append(BattleEvent.move_used(
		action.actor,
		user.pokemon.base_data.name,
		move.name
	))

	match move.category:
		"physical", "special":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_damage_move(action.actor, move, user, target))

		"status":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_status_move(move, target))

		"stat_change":
			var target := _get_move_target(move, user, opponent)
			events.append_array(_resolve_stat_change_move(move, target))

		_:
			events.append(BattleEvent.message("But it failed."))

	return events
	
func _resolve_damage_move(attacker_side: BattleDefinitions.BattleSide, move: Move, 
attacker: BattlePokemon, defender: BattlePokemon) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	if attacker == null or defender == null:
		return events

	if attacker.pokemon.current_hp <= 0:
		return events

	var old_hp = defender.pokemon.current_hp
	var damage: int = damage_calculation.get_damage(move, attacker, defender)
	defender.pokemon.current_hp = max(defender.pokemon.current_hp - damage, 0)

	var defender_side := BattleDefinitions.BattleSide.ENEMY
	if attacker_side == BattleDefinitions.BattleSide.ENEMY:
		defender_side = BattleDefinitions.BattleSide.PLAYER

	events.append(BattleEvent.hp_changed(
		defender_side,
		defender.pokemon.base_data.name,
		old_hp,
		defender.pokemon.current_hp,
		defender.pokemon.stats.values[PokemonStat.Stat.HP]
	))

	return events

func _resolve_status_move(move: Move, target: BattlePokemon) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	var status = move.status
	target.pokemon.status = status
	events.append(BattleEvent.status_applied(status))
	return events

func _resolve_stat_change_move(
	move: Move,
	target: BattlePokemon
) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	# Assume every move has max one effect for now
	var effect = move.effects[0]
	var stat_name: String = effect.stat
	var stat: int = PokemonStat.from_string(stat_name)

	var actual_change: int = target.change_stat_stage(
		stat,
		effect.stages
	)

	var pokemon_name: String = target.pokemon.base_data.name
	var display_stat_name: String = stat_name.replace("_", " ").capitalize()

	var message: String

	if actual_change == 0:
		if effect.stages > 0:
			message = "%s's %s won't go any higher!" % [
				pokemon_name,
				display_stat_name
			]
		else:
			message = "%s's %s won't go any lower!" % [
				pokemon_name,
				display_stat_name
			]

	elif actual_change == 1:
		message = "%s's %s rose!" % [
			pokemon_name,
			display_stat_name
		]

	elif actual_change == 2:
		message = "%s's %s rose sharply!" % [
			pokemon_name,
			display_stat_name
		]

	elif actual_change >= 3:
		message = "%s's %s rose drastically!" % [
			pokemon_name,
			display_stat_name
		]

	elif actual_change == -1:
		message = "%s's %s fell!" % [
			pokemon_name,
			display_stat_name
		]

	elif actual_change == -2:
		message = "%s's %s harshly fell!" % [
			pokemon_name,
			display_stat_name
		]

	else:
		message = "%s's %s severely fell!" % [
			pokemon_name,
			display_stat_name
		]

	events.append(BattleEvent.message(message))

	return events

func _resolve_switch_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	if(action.actor == BattleDefinitions.BattleSide.PLAYER):
		session.switch_player_to(action.switch_index)
	else:
		session.switch_enemy_to(action.switch_index)
	events.append(BattleEvent.battler_withdrawn(action.actor))
	events.append(BattleEvent.battler_sent_in(action.actor, action.switch_index))
	return events

func _get_ordered_actions(session: BattleSession, player_action: BattleAction, 
enemy_action: BattleAction) -> Array[BattleAction]:
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
	return user.pokemon.stats.values[PokemonStat.Stat.SPEED]

func _get_action_priority(session: BattleSession, action: BattleAction) -> int:
	# implement move priority later
	return 1

func _handle_post_action_state(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var enemy_pokemon := session.get_active_enemy().pokemon
	if enemy_pokemon.current_hp <= 0:
		return _handle_enemy_fainted(session, events)

	var player_pokemon := session.get_active_player().pokemon
	if player_pokemon.current_hp <= 0:
		return _handle_player_fainted(session, events)

	return false
	
func _handle_enemy_fainted(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var fainted_enemy := session.get_active_enemy().pokemon
	events.append(BattleEvent.fainted(BattleDefinitions.BattleSide.ENEMY, 
	fainted_enemy.base_data.name))

	_award_xp_for_enemy_faint(session, fainted_enemy, events)

	if not session.has_usable_enemy():
		if session.battle_type == BattleDefinitions.BattleType.WILD:
			_set_battle_result(session, BattleDefinitions.BattleOutcome.WILD_WIN)
		elif session.battle_type == BattleDefinitions.BattleType.TRAINER:
			_set_battle_result(session, BattleDefinitions.BattleOutcome.TRAINER_WIN)
		events.append(BattleEvent.battle_ended())
		return true

	var next_index := _find_next_usable_enemy_index(session)
	if next_index == -1:
		_set_battle_result(session, BattleDefinitions.BattleOutcome.WILD_WIN)
		events.append(BattleEvent.battle_ended())
		return true

	session.switch_enemy_to(next_index)

	events.append(BattleEvent.battler_sent_in(BattleDefinitions.BattleSide.ENEMY, next_index))
	return true

func _handle_player_fainted(session: BattleSession, events: Array[BattleEvent]) -> bool:
	var fainted_player := session.get_active_player()
	events.append(BattleEvent.fainted(BattleDefinitions.BattleSide.PLAYER, fainted_player.base_data.name))

	if not session.has_usable_player_pokemon():
		if session.battle_type == BattleDefinitions.BattleType.WILD:
			_set_battle_result(session, BattleDefinitions.BattleOutcome.WILD_LOSE)
		elif session.battle_type == BattleDefinitions.BattleType.TRAINER:
			_set_battle_result(session, BattleDefinitions.BattleOutcome.TRAINER_LOSE)
		events.append(BattleEvent.battle_ended())
		return true

	events.append(BattleEvent.message("Choose your next Pokémon."))
	events.append(BattleEvent.player_switch_required())
	return true

func _award_xp_for_enemy_faint(session: BattleSession, fainted_enemy: Pokemon, 
events: Array[BattleEvent]) -> void:
	var active_player := session.get_active_player().pokemon
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
	if outcome == BattleDefinitions.BattleOutcome.TRAINER_WIN:
		result.defeated_trainer_id = session.trainer_data.trainer_id
	session.result = result

func _opposing_side(side: BattleDefinitions.BattleSide) -> BattleDefinitions.BattleSide:
	if side == BattleDefinitions.BattleSide.PLAYER:
		return BattleDefinitions.BattleSide.ENEMY
	else:
		return BattleDefinitions.BattleSide.PLAYER

func _get_action_user(session: BattleSession, action: BattleAction) -> BattlePokemon:
	match action.actor:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_player()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_enemy()
	return null
	
func _get_action_target(session: BattleSession, action: BattleAction) -> BattlePokemon:
	match action.actor:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_enemy()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_player()
	return null

func _get_move_target(move: Move, user: BattlePokemon, opponent: BattlePokemon) -> BattlePokemon:
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
		var pokemon: Pokemon = session.enemy_party[i].pokemon
		if pokemon.current_hp > 0:
			return i
	return -1
