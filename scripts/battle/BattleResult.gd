extends RefCounted
class_name BattleResult

var battle_type: BattleDefinitions.BattleType
var outcome: BattleDefinitions.BattleOutcome

var defeated_trainer_id: String = ""
var captured_pokemon: Pokemon = null
var updated_party: Array[Pokemon] = []

static func make(
	battle_type_: BattleDefinitions.BattleType,
	outcome_: BattleDefinitions.BattleOutcome,
	defeated_trainer_id_: String = "",
	captured_pokemon_: Pokemon = null
) -> BattleResult:
	var result := BattleResult.new()
	result.battle_type = battle_type_
	result.outcome = outcome_
	result.defeated_trainer_id = defeated_trainer_id_
	result.captured_pokemon = captured_pokemon_
	return result

static func win(
	battle_type_: BattleDefinitions.BattleType,
	defeated_trainer_id_: String = ""
) -> BattleResult:
	return make(
		battle_type_,
		BattleDefinitions.BattleOutcome.WIN,
		defeated_trainer_id_
	)

static func lose(
	battle_type_: BattleDefinitions.BattleType
) -> BattleResult:
	return make(
		battle_type_,
		BattleDefinitions.BattleOutcome.LOSE,
	)

static func run() -> BattleResult:
	return make(
		BattleDefinitions.BattleType.WILD,
		BattleDefinitions.BattleOutcome.RUN
	)

static func capture(
	battle_type_: BattleDefinitions.BattleType,
	captured_pokemon_: Pokemon,
	updated_party_: Array[Pokemon] = []
) -> BattleResult:
	return make(
		battle_type_,
		BattleDefinitions.BattleOutcome.CAPTURE,
		"",
		captured_pokemon_
	)
