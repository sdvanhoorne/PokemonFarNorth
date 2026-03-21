extends RefCounted
class_name BattleStartRequest

var battle_type: BattleDefinitions.BattleType
var enemy_party: Array[Pokemon] = []
var trainer_data: BattleTrainerData
var can_run: bool = true

var player_position: Vector2
var player_direction: Vector2
var map_id: String = ""

static func make(
	battle_type_: BattleDefinitions.BattleType,
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	trainer_data_: BattleTrainerData,
	can_run_: bool = true
) -> BattleStartRequest:
	var request := BattleStartRequest.new()
	request.battle_type = battle_type_
	request.enemy_party = enemy_party_.duplicate(true)
	request.player_position = player_position_
	request.player_direction = player_direction_
	request.trainer_data = trainer_data_
	request.can_run = can_run_
	return request

static func for_wild_battle(
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	map_id_: String
) -> BattleStartRequest:
	return make(
		BattleDefinitions.BattleType.WILD,
		enemy_party_,
		player_position_,
		player_direction_,
		null,
		true
	)

static func for_trainer_battle(
	enemy_party_: Array[Pokemon],
	player_position_: Vector2,
	player_direction_: Vector2,
	trainer_data: BattleTrainerData
) -> BattleStartRequest:
	return make(
		BattleDefinitions.BattleType.TRAINER,
		enemy_party_,
		player_position_,
		player_direction_,
		trainer_data,
		false
	)

func is_trainer_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.TRAINER

func is_wild_battle() -> bool:
	return battle_type == BattleDefinitions.BattleType.WILD
