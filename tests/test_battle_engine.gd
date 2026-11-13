extends TestCase
## Tests for scripts/battle/BattleEngine.gd. Battles are built in code, no scenes.

const MINKET := 1

# --- Issue #5: player faint and switch paths ---------------------------------

func test_player_faint_with_backup_requires_switch() -> void:
	var player := _pokemon(["Tackle"], {"speed": 1})
	player.current_hp = 1
	var session := _session([player, _pokemon(["Tackle"])], [_pokemon(["Tackle"], {"attack": 200, "speed": 100})])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check(_has(events, BattleDefinitions.BattleEvent.FAINTED, BattleDefinitions.BattleSide.PLAYER), "player fainted")
	check(_has(events, BattleDefinitions.BattleEvent.SWITCH_REQUIRED), "switch required")
	check(not _has(events, BattleDefinitions.BattleEvent.BATTLE_ENDED), "battle continues")

func test_player_faint_without_backup_loses_wild_battle() -> void:
	var player := _pokemon(["Tackle"], {"speed": 1})
	player.current_hp = 1
	var session := _session([player], [_pokemon(["Tackle"], {"attack": 200, "speed": 100})])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check(_has(events, BattleDefinitions.BattleEvent.BATTLE_ENDED), "battle ended")
	check(session.result != null and session.result.outcome == BattleDefinitions.BattleOutcome.WILD_LOSE,
		"outcome is WILD_LOSE")

func test_withdrawn_event_names_outgoing_pokemon() -> void:
	var first := _pokemon(["Tackle"])
	var second := Pokemon.new_wild(7, 10)  # Ignewt, so the names differ
	second.moves = [MoveDatabase.get_move_by_name("Tackle")]
	var session := _session([first, second], [_pokemon(["Tail Whip"], {"speed": 10})])

	var events := _engine().resolve_turn(session,
		BattleAction.make_switch(BattleDefinitions.BattleSide.PLAYER, 1),
		_move(BattleDefinitions.BattleSide.ENEMY))

	var withdrawn := _find(events, BattleDefinitions.BattleEvent.BATTLER_WITHDRAWN)
	check(withdrawn != null, "withdrawn event emitted")
	if withdrawn:
		check_eq(withdrawn.payload.get("pokemon_name"), first.base_data.name, "withdrawn name")
	check_eq(session.active_player_index, 1, "active index switched")

func test_level_up_event_type() -> void:
	var e := BattleEvent.level_up("Minket", 11)
	check_eq(e.event_type, BattleDefinitions.BattleEvent.LEVEL_UP, "event type")
	check_eq(e.side, BattleDefinitions.BattleSide.PLAYER, "side")

func test_trainer_pokemon_have_battle_stats() -> void:
	# Issue #5: new_trainer_pokemon never set stats, so the trainer intro crashed.
	var team := TrainerDatabase.get_trainer_pokemon("trainer_1")
	check(not team.is_empty(), "trainer_1 has a team")
	for pokemon in team:
		check(pokemon.stats != null, "%s has stats" % pokemon.base_data.name)
		if pokemon.stats != null:
			check_eq(pokemon.current_hp, pokemon.stats.get_stat(PokemonStat.Stat.HP), "starts at full HP")
		check_eq(pokemon.status, Pokemon.status_types.NONE, "no status")

func test_level_up_recalculates_stats() -> void:
	# Issue #5: _level_up read stats.hp, which doesn't exist.
	var pokemon := Pokemon.new_wild(MINKET, 10)
	pokemon.xp_to_next_level = Pokemon.calculate_xp_to_next(10)
	pokemon.add_xp(pokemon.xp_to_next_level)
	check(pokemon.leveled_up(), "levelled up")
	check_eq(pokemon.level, 11, "level")
	check_eq(pokemon.current_hp, pokemon.stats.get_stat(PokemonStat.Stat.HP), "HP set from new stats")

func test_knockout_awards_xp_and_levels_up_without_error() -> void:
	var player := _pokemon(["Tackle"], {"attack": 200, "speed": 100})
	player.level = 10
	player.xp_to_next_level = 1  # any XP gain levels up
	var enemy := _pokemon(["Tackle"], {"speed": 1})
	enemy.current_hp = 1
	var session := _session([player], [enemy])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check(_has(events, BattleDefinitions.BattleEvent.XP_GAINED), "XP_GAINED")
	check(_has(events, BattleDefinitions.BattleEvent.LEVEL_UP, BattleDefinitions.BattleSide.PLAYER), "LEVEL_UP")
	check(_has(events, BattleDefinitions.BattleEvent.BATTLE_ENDED), "battle ended")
	check_eq(player.level, 11, "player level")

# --- Issue #6: status moves ----------------------------------------------------

func test_move_parses_effect_status() -> void:
	var thunder_wave := MoveDatabase.get_move_by_name("Thunder Wave")
	check_eq(thunder_wave.effects.size(), 1, "one effect")
	if thunder_wave.effects.size() == 1:
		check_eq(thunder_wave.effects[0].status, "paralysis", "effect status")

func test_status_from_string() -> void:
	check_eq(Pokemon.status_from_string("paralysis"), Pokemon.status_types.PARALYZED, "paralysis")
	check_eq(Pokemon.status_from_string("Burn"), Pokemon.status_types.BURNED, "Burn (any case)")
	check_eq(Pokemon.status_from_string("freeze"), Pokemon.status_types.FROZEN, "freeze")

func test_thunder_wave_paralyzes_target() -> void:
	var enemy := _pokemon(["Tail Whip"], {"speed": 10})
	var session := _session([_pokemon(["Thunder Wave"])], [enemy])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check_eq(enemy.status, Pokemon.status_types.PARALYZED, "enemy status")
	var applied := _find(events, BattleDefinitions.BattleEvent.STATUS_APPLIED)
	check(applied != null, "STATUS_APPLIED emitted")
	if applied:
		check_eq(applied.side, BattleDefinitions.BattleSide.ENEMY, "event side")
		check_eq(applied.payload.get("pokemon_name"), enemy.base_data.name, "payload pokemon_name")
		check_eq(applied.payload.get("status_type"), Pokemon.status_types.PARALYZED, "payload status_type")

func test_status_fails_if_target_already_has_one() -> void:
	var enemy := _pokemon(["Tail Whip"], {"speed": 10})
	enemy.status = Pokemon.status_types.BURNED
	var session := _session([_pokemon(["Thunder Wave"])], [enemy])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check_eq(enemy.status, Pokemon.status_types.BURNED, "status unchanged")
	check(not _has(events, BattleDefinitions.BattleEvent.STATUS_APPLIED), "no STATUS_APPLIED")
	var failed := events.any(func(e: BattleEvent) -> bool:
		return e.event_type == BattleDefinitions.BattleEvent.MESSAGE and e.payload.get("text") == "But it failed.")
	check(failed, "'But it failed.' message")

func test_self_targeting_status_move_hits_user() -> void:
	# Move data uses lowercase "self"; the engine used to match only "Self".
	var rest_like := Move.new({"name": "Test Rest", "type": "psychic", "category": "status", "target": "self",
		"effects": [{"kind": "apply_status", "target": "self", "status": "sleep"}]})
	var player := _pokemon(["Tackle"], {"speed": 100})
	player.moves = [rest_like]
	var enemy := _pokemon(["Tail Whip"], {"speed": 10})
	var session := _session([player], [enemy])

	var events := _engine().resolve_turn(session, _move(BattleDefinitions.BattleSide.PLAYER),
		_move(BattleDefinitions.BattleSide.ENEMY))

	check_eq(player.status, Pokemon.status_types.ASLEEP, "user is asleep")
	check_eq(enemy.status, Pokemon.status_types.NONE, "opponent unaffected")
	var applied := _find(events, BattleDefinitions.BattleEvent.STATUS_APPLIED)
	if applied:
		check_eq(applied.side, BattleDefinitions.BattleSide.PLAYER, "event side is the user's")

# --- Helpers ---------------------------------------------------------------------

func _engine() -> BattleEngine:
	var engine := BattleEngine.new()
	engine.setup()
	return engine

func _pokemon(move_names: Array, stat_overrides: Dictionary = {}) -> Pokemon:
	var pokemon := Pokemon.new_wild(MINKET, 10)
	var stats := {"hp": 100, "attack": 30, "defense": 30, "special_attack": 30, "special_defense": 30, "speed": 30}
	stats.merge(stat_overrides, true)
	pokemon.stats = PokemonStats.new(stats)
	pokemon.current_hp = stats["hp"]
	pokemon.status = Pokemon.status_types.NONE
	pokemon.move_names = move_names
	pokemon.moves = move_names.map(func(n: String) -> Move: return MoveDatabase.get_move_by_name(n))
	return pokemon

func _session(player_party: Array[Pokemon], enemy_party: Array[Pokemon]) -> BattleSession:
	return BattleSession.from_request(BattleStartRequest.for_wild_battle(enemy_party), player_party)

func _move(side: BattleDefinitions.BattleSide) -> BattleAction:
	return BattleAction.make_move(side, 0)

func _find(events: Array[BattleEvent], type: BattleDefinitions.BattleEvent) -> BattleEvent:
	for e in events:
		if e.event_type == type:
			return e
	return null

func _has(events: Array[BattleEvent], type: BattleDefinitions.BattleEvent, side: int = -1) -> bool:
	for e in events:
		if e.event_type == type and (side == -1 or e.side == side):
			return true
	return false
