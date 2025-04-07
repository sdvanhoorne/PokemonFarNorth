extends Node
const TypeEffectivenessChartPath = "res://data/typeEffectiveness.json"

func get_damage(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon) -> int:	
	var baseDamage = move.damage
	
	var hasStab = move.type == attackingPokemon.type1 or attackingPokemon.type2
	var stabMultiplier = 1.5 if hasStab else 1.0
	
	var physicalMove = move.category == "Physical"
	var attackerStat = attackingPokemon.attack if physicalMove else attackingPokemon.special_attack
	var defenderStat = defendingPokemon.defense if physicalMove else attackingPokemon.special_defense
	
	var typeEffectiveness1 = get_type_effectiveness(move.type, defendingPokemon.type1)
	var typeEffectiveness2
	if(defendingPokemon.type2 == null):
		typeEffectiveness2 = 1
	else:
		typeEffectiveness2 = get_type_effectiveness(move.type, defendingPokemon.type2)
	
	# might need to manage int vs float here
	# should damage round to nearest int?
	var damage = baseDamage * (attackerStat / defenderStat) 
	return damage * stabMultiplier * typeEffectiveness1 * typeEffectiveness2 / 4
	
func get_type_effectiveness(moveType: String, type: String) -> float:
	print("Getting type effectiveness")
	var file = FileAccess.open(TypeEffectivenessChartPath, FileAccess.READ)
	var typeChart = JSON.parse_string(file.get_as_text())
	return typeChart[moveType][type]
