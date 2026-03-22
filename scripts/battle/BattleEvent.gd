extends RefCounted
class_name BattleEvent

var event_type: BattleDefinitions.BattleEvent
var side: BattleDefinitions.BattleSide = BattleDefinitions.BattleSide.ENEMY
var payload: Dictionary = {}

static func message(text: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.MESSAGE
	e.payload = {
		"text": text
	}
	return e

static func move_used(side_: BattleDefinitions.BattleSide, user_name: String, move_name: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.MOVE_USED
	e.side = side_
	e.payload = {
		"user_name": user_name,
		"move_name": move_name
	}
	return e

static func move_missed(side_: BattleDefinitions.BattleSide, user_name: String, move_name: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.MOVE_MISSED
	e.side = side_
	e.payload = {
		"user_name": user_name,
		"move_name": move_name
	}
	return e

static func damage_applied(side_: BattleDefinitions.BattleSide, pokemon_name: String, damage: int, current_hp: int, max_hp: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.DAMAGE_APPLIED
	e.side = side_
	e.payload = {
		"pokemon_name": pokemon_name,
		"damage": damage,
		"current_hp": current_hp,
		"max_hp": max_hp
	}
	return e

static func hp_changed(side_: BattleDefinitions.BattleSide, pokemon_name: String, old_hp: int, current_hp: int, max_hp: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.HP_CHANGED
	e.side = side_
	e.payload = {
		"pokemon_name": pokemon_name,
		"old_hp": old_hp,
		"current_hp": current_hp,
		"max_hp": max_hp
	}
	return e

static func fainted(side_: BattleDefinitions.BattleSide, pokemon_name: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.FAINTED
	e.side = side_
	e.payload = {
		"pokemon_name": pokemon_name
	}
	return e

static func switch_performed(side_: BattleDefinitions.BattleSide, old_pokemon_name: String, new_pokemon_name: String, new_index: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.SWITCH_PERFORMED
	e.side = side_
	e.payload = {
		"old_pokemon_name": old_pokemon_name,
		"new_pokemon_name": new_pokemon_name,
		"new_index": new_index
	}
	return e

static func run_succeeded() -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.RUN_SUCCEEDED
	return e

static func run_failed(reason: String) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.RUN_FAILED
	e.payload = {
		"reason": reason
	}
	return e

static func xp_gained(pokemon_name: String, xp_gain_amount: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.XP_GAINED
	e.payload = {
		"pokemon_name": pokemon_name,
		"xp_gain_amount": xp_gain_amount
	}
	return e
	
static func level_up(pokemon_name: String, level: int) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.XP_GAINED
	e.payload = {
		"pokemon_name": pokemon_name,
		"level": level
	}
	return e

static func battle_ended(result: BattleResult) -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.BATTLE_ENDED
	return e

static func player_switch_required() -> BattleEvent:
	var e := BattleEvent.new()
	e.event_type = BattleDefinitions.BattleEvent.SWITCH_REQUIRED
	return e

static func status_applied(status: String) -> BattleEvent:
	var event := BattleEvent.new()
	event.event_type = BattleDefinitions.BattleEvent.STATUS_APPLIED
	event.payload = {
		"status": status
	}
	return event
