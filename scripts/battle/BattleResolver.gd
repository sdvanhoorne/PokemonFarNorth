extends RefCounted
class_name BattleResolver

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func resolve_turn(
	session: BattleSession,
	player_action: BattleAction,
	enemy_action: BattleAction
) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var ordered_actions := determine_turn_order(session, player_action, enemy_action)

	for action in ordered_actions:
		if session.is_over():
			break

		var user := _get_action_user(session, action)
		if user == null:
			continue

		if user.current_hp <= 0:
			continue

		events.append_array(resolve_action(session, action))

	return events

func determine_turn_order(
	session: BattleSession,
	player_action: BattleAction,
	enemy_action: BattleAction
) -> Array[BattleAction]:
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

		return rng.randi_range(0, 1) == 0
	)

	return actions

func resolve_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	match action.action_type:
		BattleDefinitions.BattleAction.MOVE:
			return _resolve_move_action(session, action)

		BattleDefinitions.BattleAction.SWITCH:
			return _resolve_switch_action(session, action)

		BattleDefinitions.BattleAction.RUN:
			return _resolve_run_action(session, action)

		BattleDefinitions.BattleAction.ITEM:
			return _resolve_item_action(session, action)

	return []

func calculate_damage(user: Pokemon, target: Pokemon, move) -> int:
	var attack_stat_name := "attack"
	var defense_stat_name := "defense"

	if "category" in move and str(move.category).to_lower() == "special":
		attack_stat_name = "special_attack"
		defense_stat_name = "special_defense"

	var level_factor := float((2 * user.level) / 5 + 2)
	var power := float(move.power)
	var attack := float(user.battle_stats.get(attack_stat_name))
	var defense := float(max(1, target.battle_stats.get(defense_stat_name)))

	var base_damage := (((level_factor * power * attack / defense) / 50.0) + 2.0)

	var modifier := 1.0
	modifier *= _random_damage_modifier()
	modifier *= _stab_modifier(user, move)
	modifier *= _type_modifier(move, target)

	return max(1, int(floor(base_damage * modifier)))

func _resolve_move_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	var user := _get_action_user(session, action)
	var target := _get_opposing_target(session, action)
	var target_side := _get_target_side(action)

	if user == null or target == null:
		return events

	if action.move_index < 0 or action.move_index >= user.moves.size():
		return events

	var move = user.moves[action.move_index]
	if move == null:
		return events

	events.append(BattleEvent.move_used(action.user_side, user.base_data.name, move.name))

	if not _check_hit(user, target, move):
		events.append(BattleEvent.move_missed(action.user_side, user.base_data.name, move.name))
		events.append(BattleEvent.message("But it missed!"))
		return events

	var old_hp = target.current_hp
	var damage := calculate_damage(user, target, move)
	target.current_hp = max(0, target.current_hp - damage)

	events.append(BattleEvent.damage_applied(
		target_side,
		target.base_data.name,
		damage,
		target.current_hp,
		target.battle_stats.hp
	))

	events.append(BattleEvent.hp_changed(
		target_side,
		target.base_data.name,
		old_hp,
		target.current_hp,
		target.battle_stats.hp
	))

	var effectiveness := _type_modifier(move, target)
	if effectiveness > 1.0:
		events.append(BattleEvent.message("It's super effective!"))
	elif effectiveness > 0.0 and effectiveness < 1.0:
		events.append(BattleEvent.message("It's not very effective..."))
	elif effectiveness == 0.0:
		events.append(BattleEvent.message("It had no effect!"))

	if target.current_hp <= 0:
		events.append(BattleEvent.fainted(target_side, target.base_data.name))

		if not _side_has_usable_pokemon(session, target_side):
			var result := BattleResult.new()
			result.battle_type = session.battle_type

			if target_side == BattleDefinitions.BattleSide.ENEMY:
				result.outcome = BattleDefinitions.BattleOutcome.WIN
			else:
				result.outcome = BattleDefinitions.BattleOutcome.LOSE

			session.result = result

	return events

func _resolve_switch_action(session: BattleSession, action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	match action.user_side:
		BattleDefinitions.BattleSide.PLAYER:
			if action.switch_index < 0 or action.switch_index >= session.player_party.size():
				return events

			var old_pokemon := session.get_active_player()
			var new_pokemon = session.player_party[action.switch_index]

			if new_pokemon.current_hp <= 0:
				return events

			if action.switch_index == session.active_player_index:
				return events

			session.switch_player_to(action.switch_index)

			events.append(BattleEvent.switch_performed(
				BattleDefinitions.BattleSide.PLAYER,
				old_pokemon.base_data.name,
				new_pokemon.base_data.name,
				action.switch_index
			))

		BattleDefinitions.BattleSide.ENEMY:
			if action.switch_index < 0 or action.switch_index >= session.enemy_party.size():
				return events

			var old_enemy := session.get_active_enemy()
			var new_enemy = session.enemy_party[action.switch_index]

			if new_enemy.current_hp <= 0:
				return events

			if action.switch_index == session.active_enemy_index:
				return events

			session.switch_enemy_to(action.switch_index)

			events.append(BattleEvent.switch_performed(
				BattleDefinitions.BattleSide.ENEMY,
				old_enemy.base_data.name,
				new_enemy.base_data.name,
				action.switch_index
			))

	return events

func _resolve_run_action(session: BattleSession, _action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []

	if session.battle_type == BattleDefinitions.BattleType.TRAINER:
		events.append(BattleEvent.run_failed("No! There's no running from a trainer battle!"))
		return events

	if not session.can_run:
		events.append(BattleEvent.run_failed("You can't run from this battle!"))
		return events

	var escaped := _try_escape(session)
	if escaped:
		var result := BattleResult.new()
		result.battle_type = session.battle_type
		result.outcome = BattleDefinitions.BattleOutcome.ESCAPE
		session.result = result

		events.append(BattleEvent.run_succeeded())
	else:
		events.append(BattleEvent.run_failed("Couldn't escape!"))

	return events

func _resolve_item_action(_session: BattleSession, _action: BattleAction) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	events.append(BattleEvent.message("Items are not implemented yet."))
	return events

func _check_hit(_user: Pokemon, _target: Pokemon, move) -> bool:
	if not ("accuracy" in move):
		return true

	var accuracy := int(move.accuracy)
	if accuracy >= 100:
		return true

	var roll := rng.randi_range(1, 100)
	return roll <= accuracy

func _try_escape(session: BattleSession) -> bool:
	var player := session.get_active_player()
	var enemy := session.get_active_enemy()

	if player == null or enemy == null:
		return false

	if player.battle_stats.speed >= enemy.battle_stats.speed:
		return true

	return rng.randi_range(0, 99) < 50

func _get_action_priority(session: BattleSession, action: BattleAction) -> int:
	match action.action_type:
		BattleDefinitions.BattleAction.SWITCH:
			return 6

		BattleDefinitions.BattleAction.ITEM:
			return 5

		BattleDefinitions.BattleAction.RUN:
			return 4

		BattleDefinitions.BattleAction.MOVE:
			var user := _get_action_user(session, action)
			if user != null and action.move_index >= 0 and action.move_index < user.moves.size():
				var move = user.moves[action.move_index]
				if "priority" in move:
					return int(move.priority)
			return 0

	return 0

func _get_action_speed(session: BattleSession, action: BattleAction) -> int:
	var user := _get_action_user(session, action)
	if user == null:
		return 0
	return int(user.battle_stats.speed)

func _get_action_user(session: BattleSession, action: BattleAction) -> Pokemon:
	match action.user_side:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_player()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_enemy()
	return null

func _get_opposing_target(session: BattleSession, action: BattleAction) -> Pokemon:
	match action.user_side:
		BattleDefinitions.BattleSide.PLAYER:
			return session.get_active_enemy()
		BattleDefinitions.BattleSide.ENEMY:
			return session.get_active_player()
	return null

func _get_target_side(action: BattleAction) -> BattleDefinitions.BattleSide:
	match action.user_side:
		BattleDefinitions.BattleSide.PLAYER:
			return BattleDefinitions.BattleSide.ENEMY
		BattleDefinitions.BattleSide.ENEMY:
			return BattleDefinitions.BattleSide.PLAYER
	return BattleDefinitions.BattleSide.ENEMY

func _side_has_usable_pokemon(session: BattleSession, side: BattleDefinitions.BattleSide) -> bool:
	match side:
		BattleDefinitions.BattleSide.PLAYER:
			return session.has_usable_player()
		BattleDefinitions.BattleSide.ENEMY:
			return session.has_usable_enemy()
	return false

func _random_damage_modifier() -> float:
	return rng.randf_range(0.85, 1.0)

func _stab_modifier(user: Pokemon, move) -> float:
	if not ("type" in move):
		return 1.0

	if user.base_data.types.has(move.type):
		return 1.5

	return 1.0

func _type_modifier(move, target: Pokemon) -> float:
	if not ("type" in move):
		return 1.0

	var modifier := 1.0

	for target_type in target.base_data.types:
		modifier *= _get_type_effectiveness(move.type, target_type)

	return modifier

func _get_type_effectiveness(attack_type: String, defense_type: String) -> float:
	if Helpers.has_method("get_type_effectiveness"):
		return float(Helpers.get_type_effectiveness(attack_type, defense_type))

	return 1.0
