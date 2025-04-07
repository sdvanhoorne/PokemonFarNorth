extends Node
const Move = preload("res://scripts/moves/Move.gd")
var TypeEffectivenessChart = preload("res://data/typeEffectiveness.json")

func get_damage(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon):	
	var baseDamage = move.get("damage")
	
	var hasStab = move.get("type") == (attackingPokemon.type1 or attackingPokemon.type2)
	var stabMultiplier = 1.5 if hasStab else 1.0
	
	var physicalMove = move.get("category") == "Physical"
	var attackerStat = attackingPokemon.attack if physicalMove else attackingPokemon.special_attack
	var defenderStat = defendingPokemon.defense if physicalMove else attackingPokemon.special_defense
	
	var typeEffectiveness1 = get_type_effectiveness(move.get("type"), defendingPokemon.type1)
	var typeEffectiveness2 = get_type_effectiveness(move.get("type"), defendingPokemon.type2)
	
	var damage = baseDamage * (attackerStat / defenderStat) 
	damage = damage * stabMultiplier * typeEffectiveness1 * typeEffectiveness2 / 8
	
func get_type_effectiveness(moveType: String, type: String) -> float:
	print("Getting type effectiveness")
	return TypeEffectivenessChart[moveType][type]
