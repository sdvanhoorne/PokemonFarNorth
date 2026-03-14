extends RefCounted
class_name BattleResult

var battle_type: BattleDefinitions.BattleType
var outcome: BattleDefinitions.BattleOutcome
var defeated_trainer_id: int
var captured_pokemon: Pokemon
var updated_party: Array[Pokemon]
# return_context
