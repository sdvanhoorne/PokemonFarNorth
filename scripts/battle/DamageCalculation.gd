extends Node
class_name DamageCalculation

const TypeEffectivenessChartPath = "res://data/types/type_effectiveness.json"

func get_damage(move: Move, attacker: BattlePokemon, defender: BattlePokemon) -> int:	
	var has_stab = move.type == attacker.pokemon.base_data.type1 or attacker.pokemon.base_data.type2
	var stab_multiplier = 1.5 if has_stab else 1.0
	
	var physical_move := move.category.to_lower() == "physical"
	var attacker_stat: int
	var defender_stat: int

	if physical_move:
		attacker_stat = attacker.get_effective_stat(
			PokemonStat.Stat.ATTACK
		)
		defender_stat = defender.get_effective_stat(
			PokemonStat.Stat.DEFENSE
		)
	else:
		attacker_stat = attacker.get_effective_stat(
			PokemonStat.Stat.SPECIAL_ATTACK
		)
		defender_stat = defender.get_effective_stat(
			PokemonStat.Stat.SPECIAL_DEFENSE
		)
	
	var type_effectiveness_1 = get_type_effectiveness(move.type, defender.pokemon.base_data.type1)
	var type_effectiveness_2
	if(defender.pokemon.base_data.type2 == ""):
		type_effectiveness_2 = 1.0
	else:
		type_effectiveness_2 = get_type_effectiveness(move.type, defender.pokemon.base_data.type2)
	
	var damage = move.power * (float(attacker_stat) / float(defender_stat)) 
	damage =  damage * stab_multiplier * type_effectiveness_1 * type_effectiveness_2 / 6
	return int(ceil(damage))
	
func get_type_effectiveness(move_type: String, type: String) -> float:
	var file = FileAccess.open(TypeEffectivenessChartPath, FileAccess.READ)
	var typeChart = JSON.parse_string(file.get_as_text())
	return typeChart[move_type.to_lower()][type.to_lower()]
