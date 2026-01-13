class_name BattleEngine
extends RefCounted

enum Side { PLAYER, ENEMY }

# --- Event helpers -----------------------------------------------------------

static func msg(text: String) -> Dictionary:
	return {"type": "message", "text": text}

static func hp_change(side: int, new_hp: int, max_hp: int, amount: int) -> Dictionary:
	return {"type": "hp_change", "side": side, "new_hp": new_hp, "max_hp": max_hp, "amount": amount}

static func faint(side: int, name: String) -> Dictionary:
	return {"type": "faint", "side": side, "name": name}

static func xp_gain(amount: int, name: String) -> Dictionary:
	return {"type": "xp_gain", "amount": amount, "name": name}

static func level_up(name: String, level: String) -> Dictionary:
	return {"type": "level_up", "name": name, "level": level}

static func battle_end(result: String) -> Dictionary:
	# result: "player_win" / "player_lose" / "fled" etc
	return {"type": "battle_end", "result": result}

# --- Public API --------------------------------------------------------------

# state is a Dictionary
# {
#   "player_party": Array[Pokemon],
#   "enemy_party": Array[Pokemon],
#   "player_active": int,
#   "enemy_active": int,
#   "rng": RandomNumberGenerator (optional)
# }
func resolve_turn(state: Dictionary, player_move_index: int, enemy_move_name: String) -> Dictionary:
	var events: Array = []

	var player_pokemon: Pokemon = _player_active(state)
	var enemy_pokemon: Pokemon = _enemy_active(state)

	# Validate move index
	if player_move_index < 0 or player_move_index >= player_pokemon.moves.size():
		events.append(msg("Invalid move."))
		return {"state": state, "events": events}

	var player_move: Move = player_pokemon.moves[player_move_index]
	var enemy_move: Move = MoveDatabase.get_move_by_name(enemy_move_name)

	# Decide order (priority not implemented here; add later)
	var first_side: int = Side.PLAYER if player_pokemon.battle_stats.speed >= enemy_pokemon.battle_stats.speed else Side.ENEMY
	var second_side: int = Side.ENEMY if first_side == Side.PLAYER else Side.PLAYER

	# Execute first action
	_execute_move(state, first_side, player_move, enemy_move, events)
	if _is_battle_over_or_faint_handled(state, events):
		return {"state": state, "events": events}

	# Execute second action (re-pull active Pokémon in case something fainted/swapped)
	_execute_move(state, second_side, player_move, enemy_move, events)
	_is_battle_over_or_faint_handled(state, events)

	return {"state": state, "events": events}

# --- Core resolution ---------------------------------------------------------

func _execute_move(state: Dictionary, side: int, player_move: Move, enemy_move: Move, events: Array) -> void:
	var attacker: Pokemon
	var defender: Pokemon
	var move: Move

	if side == Side.PLAYER:
		attacker = _player_active(state)
		defender = _enemy_active(state)
		move = player_move
	else:
		attacker = _enemy_active(state)
		defender = _player_active(state)
		move = enemy_move

	# If attacker already fainted (possible if you later add recoil/end-of-turn etc)
	if attacker.current_hp <= 0:
		return

	events.append(msg("%s used %s" % [attacker.base_data.name, move.name]))

	match move.category:
		"Physical", "Special":
			_apply_damage(state, side, move, attacker, defender, events)
		"Status":
			_apply_status(move, attacker, defender, events)
		"StatChange":
			_apply_stat_change(move, attacker, defender, events)
		_:
			events.append(msg("But it failed."))

func _apply_damage(state: Dictionary, attacker_side: int, move: Move, attacker: Pokemon, defender: Pokemon, events: Array) -> void:
	var damage: int = DamageCalculation.get_damage(move, attacker, defender)
	if damage < 0:
		damage = 0

	defender.current_hp = max(defender.current_hp - damage, 0)

	var defender_side: int = Side.ENEMY if attacker_side == Side.PLAYER else Side.PLAYER
	events.append(hp_change(defender_side, defender.current_hp, defender.battle_stats.hp, -damage))

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

# --- Faint handling / battle end --------------------------------------------

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
		
		# check for level ups
		while player_pokemon.leveled_up():
			events.append(level_up(player_pokemon.base_data.name, player_pokemon.level))

		# Remove enemy active from party, advance if possible
		state.enemy_party.pop_at(state.enemy_active)
		if state.enemy_party.size() == 0:
			events.append(battle_end("player_win"))
			return true

		# Clamp active index
		state.enemy_active = clamp(state.enemy_active, 0, state.enemy_party.size() - 1)
		events.append(msg("Enemy sent out %s!" % _enemy_active(state).base_data.name))
		return true 

	# Player fainted
	if player_pokemon.current_hp <= 0:
		events.append(faint(Side.PLAYER, player_pokemon.base_data.name))

		state.player_party.pop_at(state.player_active)
		if state.player_party.size() == 0:
			events.append(battle_end("player_lose"))
			return true

		state.player_active = clamp(state.player_active, 0, state.player_party.size() - 1)
		events.append(msg("Go %s!" % _player_active(state).base_data.name))
		return true

	return false

# --- Helpers ----------------------------------------------------------------

func _player_active(state: Dictionary) -> Pokemon:
	return state.player_party[state.player_active]

func _enemy_active(state: Dictionary) -> Pokemon:
	return state.enemy_party[state.enemy_active]
