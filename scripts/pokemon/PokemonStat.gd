class_name PokemonStat
extends RefCounted

enum Stat {
	HP,
	ATTACK,
	DEFENSE,
	SPECIAL_ATTACK,
	SPECIAL_DEFENSE,
	SPEED,
	ACCURACY,
	EVASION
}

static func from_string(stat_name: String) -> int:
	match stat_name.to_lower():
		"hp":
			return Stat.HP
		"attack":
			return Stat.ATTACK
		"defense":
			return Stat.DEFENSE
		"special_attack":
			return Stat.SPECIAL_ATTACK
		"special_defense":
			return Stat.SPECIAL_DEFENSE
		"speed":
			return Stat.SPEED
		"accuracy":
			return Stat.ACCURACY
		"evasion":
			return Stat.EVASION
		_:
			push_error("Unknown Pokemon stat: " + stat_name)
			return -1
