extends Node
const TypeEffectivenessChartPath = "res://data/typeEffectiveness.json"

func get_damage(move: Move, attackingPokemon: Pokemon, defendingPokemon: Pokemon) -> int:	
	var baseDamage = move.Damage
	
	var hasStab = move.Type == attackingPokemon.Type1 or attackingPokemon.Type2
	var stabMultiplier = 1.5 if hasStab else 1.0
	
	var physicalMove = move.Category == "Physical"
	var attackerStat
	var defenderStat
	if physicalMove:
		attackerStat = attackingPokemon.BattleStats.Attack
		defenderStat = defendingPokemon.BattleStats.Defense 
	else:
		attackerStat = attackingPokemon.BattleStats.Special_Attack
		defenderStat = defendingPokemon.BattleStats.Special_Defense
	
	var typeEffectiveness1 = get_type_effectiveness(move.Type, defendingPokemon.Type1)
	var typeEffectiveness2
	if(defendingPokemon.Type2 == null):
		typeEffectiveness2 = 1.0
	else:
		typeEffectiveness2 = get_type_effectiveness(move.Type, defendingPokemon.Type2)
	
	# might need to manage int vs float here
	# should damage round to nearest int?
	var damage = baseDamage * (float(attackerStat) / float(defenderStat)) 
	damage =  damage * stabMultiplier * typeEffectiveness1 * typeEffectiveness2 / 6
	return int(damage)
	
func get_type_effectiveness(moveType: String, type: String) -> float:
	print("Getting type effectiveness")
	var file = FileAccess.open(TypeEffectivenessChartPath, FileAccess.READ)
	var typeChart = JSON.parse_string(file.get_as_text())
	return typeChart[moveType][type]
