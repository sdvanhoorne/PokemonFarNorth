extends RefCounted
class_name BattleStateMachine

signal state_changed(old_state: BattleDefinitions.BattlePhase, new_state: BattleDefinitions.BattlePhase)

var current_state: BattleDefinitions.BattlePhase = BattleDefinitions.BattlePhase.INTRO
var previous_state: BattleDefinitions.BattlePhase = BattleDefinitions.BattlePhase.INTRO

func change_state(new_state: BattleDefinitions.BattlePhase) -> void:
	if current_state == new_state:
		return

	var old_state := current_state
	previous_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

func can_open_moves() -> bool:
	return current_state == BattleDefinitions.BattlePhase.COMMAND

func can_open_party() -> bool:
	return current_state in [
		BattleDefinitions.BattlePhase.COMMAND,
		BattleDefinitions.BattlePhase.FORCED_SWITCH
	]

func can_open_items() -> bool:
	return current_state == BattleDefinitions.BattlePhase.COMMAND

func can_attempt_run(session: BattleSession) -> bool:
	return current_state == BattleDefinitions.BattlePhase.COMMAND and session.can_run

func requires_player_choice() -> bool:
	return current_state in [
		BattleDefinitions.BattlePhase.COMMAND,
		BattleDefinitions.BattlePhase.MOVE_SELECT,
		BattleDefinitions.BattlePhase.PARTY_SELECT,
		BattleDefinitions.BattlePhase.ITEM_SELECT,
		BattleDefinitions.BattlePhase.FORCED_SWITCH
	]

func blocks_general_input() -> bool:
	return current_state in [
		BattleDefinitions.BattlePhase.INTRO,
		BattleDefinitions.BattlePhase.RESOLVING_TURN,
		BattleDefinitions.BattlePhase.MESSAGE,
		BattleDefinitions.BattlePhase.VICTORY,
		BattleDefinitions.BattlePhase.DEFEAT,
		BattleDefinitions.BattlePhase.ESCAPE,
		BattleDefinitions.BattlePhase.CAPTURE,
		BattleDefinitions.BattlePhase.ENDED
	]

func is_terminal() -> bool:
	return current_state in [
		BattleDefinitions.BattlePhase.VICTORY,
		BattleDefinitions.BattlePhase.DEFEAT,
		BattleDefinitions.BattlePhase.ESCAPE,
		BattleDefinitions.BattlePhase.CAPTURE,
		BattleDefinitions.BattlePhase.ENDED
	]

func can_cancel() -> bool:
	return current_state in [
		BattleDefinitions.BattlePhase.MOVE_SELECT,
		BattleDefinitions.BattlePhase.PARTY_SELECT,
		BattleDefinitions.BattlePhase.ITEM_SELECT
	]

func go_back() -> void:
	match current_state:
		BattleDefinitions.BattlePhase.MOVE_SELECT, BattleDefinitions.BattlePhase.PARTY_SELECT, BattleDefinitions.BattlePhase.ITEM_SELECT:
			change_state(BattleDefinitions.BattlePhase.COMMAND)
