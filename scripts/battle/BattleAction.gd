extends Node

class_name BattleAction
enum battle_action_type { MOVE, SWITCH, ITEM, RUN }

var actor: String = ""
var action_type: battle_action_type
var move_index: int = 0
var switch_index: int = 0
var priority: int = 0
var speed: int = 0

static func make_move(actor: String, move_index: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action_type = battle_action_type.MOVE
	a.move_index = move_index
	a.switch_index = -1
	return a

static func make_switch(actor: String, party_index: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action_type = battle_action_type.SWITCH
	a.switch_index = party_index
	a.move_index = -1
	return a

static func make_item(actor: String) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action_type = battle_action_type.ITEM
	return a

static func make_run(actor: String) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action_type = battle_action_type.RUN
	return a
