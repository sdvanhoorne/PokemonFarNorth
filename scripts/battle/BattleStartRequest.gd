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

static func make(
	battle_type_: BattleDefinitions.BattleType,
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	map_id_: String,
	trainer_id_: String = "",
	trainer_name_: String = "",
	intro_lines_: PackedStringArray = PackedStringArray(),
	can_run_: bool = true
) -> BattleStartRequest:
	var request := BattleStartRequest.new()
	request.battle_type = battle_type_
	request.enemy_party = enemy_party_.duplicate(true)
	request.player_position = player_position_
	request.player_direction = player_direction_
	request.map_id = map_id_
	request.trainer_id = trainer_id_
	request.trainer_name = trainer_name_
	request.intro_lines = intro_lines_
	request.can_run = can_run_
	return request

static func for_wild_battle(
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	map_id_: String,
	intro_lines_: PackedStringArray = PackedStringArray()
) -> BattleStartRequest:
	return make(
		BattleDefinitions.BattleType.WILD,
		enemy_party_,
		player_position_,
		player_direction_,
		map_id_,
		"",
		"",
		intro_lines_,
		true
	)

static func for_trainer_battle(
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	map_id_: String,
	trainer_id_: String,
	trainer_name_: String,
	intro_lines_: PackedStringArray = PackedStringArray()
) -> BattleStartRequest:
	return make(
		BattleDefinitions.BattleType.TRAINER,
		enemy_party_,
		player_position_,
		player_direction_,
		map_id_,
		trainer_id_,
		trainer_name_,
		intro_lines_,
		false
	)

func is_trainer_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.TRAINER

func is_wild_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.WILD
