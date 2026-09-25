extends RefCounted
class_name BattleAction

var actor: BattleDefinitions.BattleSide
var action: BattleDefinitions.BattleAction
var move_index: int = 0
var switch_index: int = 0
var priority: int = 0
var speed: int = 0

static func make_move(actor_: BattleDefinitions.BattleSide, move_index_: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor_
	a.action = BattleDefinitions.BattleAction.MOVE
	a.move_index = move_index_
	a.switch_index = -1
	return a

static func make_switch(actor_: BattleDefinitions.BattleSide, party_index: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor_
	a.action = BattleDefinitions.BattleAction.SWITCH
	a.switch_index = party_index
	a.move_index = -1
	return a

static func make_item(actor_: BattleDefinitions.BattleSide) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor_
	a.action = BattleDefinitions.BattleAction.ITEM
	return a

static func make_run(actor_: BattleDefinitions.BattleSide) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor_
	a.action = BattleDefinitions.BattleAction.RUN
	return a
