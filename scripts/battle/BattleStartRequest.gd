extends RefCounted
class_name BattleStartRequest

var battle_type: BattleDefinitions.BattleType
var enemy_party: Array[Pokemon] = []
var trainer_id: String = ""
var trainer_name: String = ""
var intro_lines: PackedStringArray = []
var can_run: bool = true

var player_position: Vector2
var player_direction: Vector2
var map_id: String = ""

func is_trainer_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.TRAINER

func is_wild_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.WILD
