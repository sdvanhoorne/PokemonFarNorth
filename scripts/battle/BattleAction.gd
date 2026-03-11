extends RefCounted
class_name BattleAction

var actor: BattleDefinitions.BattleSide
var action: BattleDefinitions.BattleAction
var move_index: int = 0
var switch_index: int = 0
var priority: int = 0
var speed: int = 0

static func make_move(actor: BattleDefinitions.BattleSide, move_index: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action = BattleDefinitions.BattleAction.MOVE
	a.move_index = move_index
	a.switch_index = -1
	return a

static func make_switch(actor: BattleDefinitions.BattleSide, party_index: int) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action = BattleDefinitions.BattleAction.SWITCH
	a.switch_index = party_index
	a.move_index = -1
	return a

static func make_item(actor: BattleDefinitions.BattleSide) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action = BattleDefinitions.BattleAction.ITEM
	return a

static func make_run(actor: BattleDefinitions.BattleSide) -> BattleAction:
	var a := BattleAction.new()
	a.actor = actor
	a.action = BattleDefinitions.BattleAction.RUN
	return a
