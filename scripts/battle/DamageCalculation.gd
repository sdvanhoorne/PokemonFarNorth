extends RefCounted
class_name DamageCalculation

const TypeEffectivenessChartPath = "res://data/types/type_effectiveness.json"

func get_damage(move: Move, attacker: BattlePokemon, defender: BattlePokemon) -> int:	
	var stab_multiplier := 1.5 if has_stab(move, attacker) else 1.0
	
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
	
## Same-type attack bonus: the move's type matches either of the attacker's types.
## Move data uses lowercase types ("fire") and species data capitalized ("Fire"), so
## compare case-insensitively. type2 is "" for single types, so a typeless move
## (e.g. an unknown move from MoveDatabase) must not count as matching it.
func has_stab(move: Move, attacker: BattlePokemon) -> bool:
	var move_type := move.type.to_lower()
	if move_type == "":
		return false
	var species := attacker.pokemon.base_data
	return move_type == species.type1.to_lower() or move_type == species.type2.to_lower()

func get_type_effectiveness(move_type: String, type: String) -> float:
	var row: Dictionary = _get_type_chart().get(move_type.to_lower(), {})
	var key := type.to_lower()
	if not row.has(key):
		push_warning("DamageCalculation: no type chart entry for %s -> %s" % [move_type, type])
		return 1.0
	return float(row[key])

# The chart is parsed once and shared by every DamageCalculation instance.
static var _type_chart: Dictionary = {}

static func _get_type_chart() -> Dictionary:
	if _type_chart.is_empty():
		var file := FileAccess.open(TypeEffectivenessChartPath, FileAccess.READ)
		if file == null:
			push_error("DamageCalculation: could not open %s" % TypeEffectivenessChartPath)
			return _type_chart
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_type_chart = parsed
		else:
			push_error("DamageCalculation: %s is not a JSON object" % TypeEffectivenessChartPath)
	return _type_chart
