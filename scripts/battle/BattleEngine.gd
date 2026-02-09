# BattleEngine handles battle logic
# updates Pokemon objects
# and queues events for the BattleController

class_name BattleEngine
extends RefCounted

enum Side { PLAYER, ENEMY }

# Event objects 

static func msg(text: String) -> Dictionary:
	return {"type": "message", "text": text}

static func switch(side: int, switch_index: int) -> Dictionary:
	return { "type": "switch", "side": side, "switch_index": switch_index}

static func hp_change(side: int, damage: int) -> Dictionary:
	return {"type": "hp_change", "side": side, "damage": damage}

static func faint(side: int, name: String) -> Dictionary:
	return {"type": "faint", "side": side, "name": name}

static func xp_gain(amount: int, name: String) -> Dictionary:
	return {"type": "xp_gain", "amount": amount, "name": name}

static func level_up(name: String, level: String) -> Dictionary:
	return {"type": "level_up", "name": name, "level": level}

static func battle_end(result: String) -> Dictionary:
	# result: "player_win" / "player_lose" / "fled" etc
	return {"type": "battle_end", "result": result}

func resolve_turn(player_action: BattleAction, enemy_action: BattleAction, state: Dictionary):
	var events: Array = []
	
	var player_pokemon: Pokemon = _player_active(state)
	var enemy_pokemon: Pokemon = _enemy_active(state)
	
	# determine first side to go via speed
	var first_side: int = Side.PLAYER if player_pokemon.battle_stats.speed >= enemy_pokemon.battle_stats.speed else Side.ENEMY
	var second_side: int = Side.ENEMY if first_side == Side.PLAYER else Side.PLAYER
	
	# if player faster
	if(first_side == Side.PLAYER):
	# player switch
		if(player_action.action_type == BattleAction.battle_action_type.SWITCH):
			events.append(switch(Side.PLAYER, player_action.switch_index))
			events.append(msg("You sent out %s" % [PlayerInventory.PartyPokemon[player_action.switch_index].base_data.name]))
			player_pokemon = _execute_switch(Side.PLAYER, player_action.switch_index, state)
	# enemy switch
		if(enemy_action.action_type == BattleAction.battle_action_type.SWITCH):
			events.append(switch(Side.ENEMY, enemy_action.switch_index))
			events.append(msg("Opponent sent out %s" % [state.enemy_party[enemy_action.switch_index].base_data.name]))
			enemy_pokemon = _execute_switch(Side.ENEMY, enemy_action.switch_index, state)
	# player move
		if(player_action.action_type == BattleAction.battle_action_type.MOVE):
			var player_move: Move = player_pokemon.moves[player_action.move_index]
			_execute_move(Side.PLAYER, player_pokemon, enemy_pokemon, player_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	# enemy move
		if(enemy_action.action_type == BattleAction.battle_action_type.MOVE):
			var enemy_move: Move = enemy_pokemon.moves[enemy_action.move_index]
			_execute_move(Side.ENEMY, enemy_pokemon, player_pokemon, enemy_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}

	# if enemy faster
	else:
	# enemy switch
		if(enemy_action.action_type == BattleAction.battle_action_type.SWITCH):
			events.append(switch(Side.ENEMY, enemy_action.switch_index))
			events.append(msg("Opponent sent out %s" % [state.enemy_party[enemy_action.switch_index].base_data.name]))
			enemy_pokemon = _execute_switch(Side.ENEMY, enemy_action.switch_index, state)
	# player switch
		if(player_action.action_type == BattleAction.battle_action_type.SWITCH):
			events.append(switch(Side.PLAYER, player_action.switch_index))
			events.append(msg("You sent out %s" % [PlayerInventory.PartyPokemon[player_action.switch_index].base_data.name]))
			player_pokemon = _execute_switch(Side.PLAYER, player_action.switch_index, state)
	# enemy move
		if(enemy_action.action_type == BattleAction.battle_action_type.MOVE):
			var enemy_move: Move = enemy_pokemon.moves[enemy_action.move_index]
			_execute_move(Side.ENEMY, enemy_pokemon, player_pokemon, enemy_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	# player move
		if(player_action.action_type == BattleAction.battle_action_type.MOVE):
			var player_move: Move = player_pokemon.moves[player_action.move_index]
			_execute_move(Side.PLAYER, player_pokemon, enemy_pokemon, player_move, events)
			if _is_battle_over_or_faint_handled(state, events):
				return {"state": state, "events": events}
	
	return {"state": state, "events": events}

func _execute_switch(side: int, switch_index: int, state: Dictionary) -> Pokemon:
	if(side == Side.PLAYER):
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
	var damage: int = DamageCalculation.get_damage(move, attacker, defender)
	var old_hp = defender.current_hp
	var new_hp = max(defender.current_hp - damage, 0)
	defender.current_hp -= damage
	var defender_side: int = Side.ENEMY if attacker_side == Side.PLAYER else Side.PLAYER
	events.append(hp_change(defender_side, damage))

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

func _is_battle_over_or_faint_handled(state: Dictionary, events: Array) -> bool:
	var player_pokemon: Pokemon = _player_active(state)
	var enemy_pokemon: Pokemon = _enemy_active(state)

	# Enemy fainted
	if enemy_pokemon.current_hp <= 0:
		events.append(faint(Side.ENEMY, enemy_pokemon.base_data.name))

		# give xp
		var xp_gain_amount: int = enemy_pokemon.calculate_xp_given()
		_player_active(state).add_xp(xp_gain_amount)
		events.append(xp_gain(xp_gain_amount, player_pokemon.base_data.name))
		
		# check for level ups - maybe pull this out into another function
		while player_pokemon.leveled_up():
			events.append(level_up(player_pokemon.base_data.name, str(player_pokemon.level)))

		# Remove enemy active from party, advance if possible
		if _all_fainted(state.enemy_party):
			events.append(battle_end("player_win"))
			return true

		# TODO Clamp active index / determine next enemy pokemon
		state.enemy_active = clamp(state.enemy_active, 0, state.enemy_party.size() - 1)
		events.append(switch(Side.ENEMY, state.enemy_active))
		events.append(msg("Enemy sent out %s!" % _enemy_active(state).base_data.name))
		return true 

	# Player fainted
	if player_pokemon.current_hp <= 0:
		events.append(faint(Side.PLAYER, player_pokemon.base_data.name))

		if _all_fainted(state.player_party):
			events.append(battle_end("player_lose"))
			return true
	
		# TODO show player party UI and get new active pokemon 
		state.player_active = clamp(state.player_active, 0, state.player_party.size() - 1)
		events.append(msg("Go %s!" % _player_active(state).base_data.name))
		return true

	return false

# --- Helpers ----------------------------------------------------------------

func _all_fainted(pokemons: Array) -> bool:
	for pokemon in pokemons:
		if(pokemon.current_hp > 0):
			return false
	return true

func _player_active(state: Dictionary) -> Pokemon:
	return state.player_party[state.player_active]

func _enemy_active(state: Dictionary) -> Pokemon:
	return state.enemy_party[state.enemy_active]
