extends Node
const TypeEffectivenessChartPath = "res://data/types/type_effectiveness.json"

func get_damage(move: Move, attacking_pokemon: Pokemon, defending_pokemon: Pokemon) -> int:	
	var has_stab = move.type == attacking_pokemon.base_data.type1 or attacking_pokemon.base_data.type2
	var stab_multiplier = 1.5 if has_stab else 1.0
	
	var physical_move = move.category == "Physical"
	var attacker_stat
	var defender_stat
	if physical_move:
		attacker_stat = attacking_pokemon.battle_stats.attack
		defender_stat = defending_pokemon.battle_stats.defense 
	else:
		attacker_stat = attacking_pokemon.battle_stats.special_attack
		defender_stat = defending_pokemon.battle_stats.special_defense
	
	var type_effectiveness_1 = get_type_effectiveness(move.type, defending_pokemon.base_data.type1)
	var type_effectiveness_2
	if(defending_pokemon.base_data.type2 == ""):
		type_effectiveness_2 = 1.0
	else:
		type_effectiveness_2 = get_type_effectiveness(move.type, defending_pokemon.base_data.type2)
	
	# might need to manage int vs float here
	# should damage round to nearest int?
	var damage = move.power * (float(attacker_stat) / float(defender_stat)) 
	damage =  damage * stab_multiplier * type_effectiveness_1 * type_effectiveness_2 / 6
	return int(damage)
	
func get_type_effectiveness(move_type: String, type: String) -> float:
	var file = FileAccess.open(TypeEffectivenessChartPath, FileAccess.READ)
	var typeChart = JSON.parse_string(file.get_as_text())
	return typeChart[move_type][type]
