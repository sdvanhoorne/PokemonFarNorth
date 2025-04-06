extends Node

func get_damage(moveName: String, attackingPokemon: Pokemon, defendingPokemon: Pokemon):
	var movesData = FileAccess.open("res://data/moves.json", FileAccess.READ)
	var move = JSON.parse_string(movesData.get_as_text())["moves"][moveName]
	
	var hasStab = move.get("type") == (attackingPokemon.type1 or attackingPokemon.type2)
	var stabMultiplier = 1.5 if hasStab else 1.0
	
	var attackerStat = attackingPokemon.attack if move.get("category") == "Physical" else attackingPokemon.special_attack
	var defenderStat = defendingPokemon.defense if move.get("category") == "Physical" else attackingPokemon.special_defense
	
	var damage = move.get("damage") * (attackerStat / defenderStat) * stabMultiplier
	damage = damage * get_type_effectiveness(move.get("type"), defendingPokemon.type1)
	damage = damage * get_type_effectiveness(move.get("type"), defendingPokemon.type2)
	
func get_type_effectiveness(moveType: String, type: String) -> float:
	print("Getting type effectiveness")
	# get effectiveness multiple from data
	return 1
