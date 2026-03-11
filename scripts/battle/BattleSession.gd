extends RefCounted
class_name BattleSession

var battle_type: BattleDefinitions.BattleType
var player_party: Array[Pokemon]
var enemy_party: Array[Pokemon]
var active_player_index: int
var active_enemy_index: int
var can_run: bool
var trainer_data: Dictionary
var state
var turn_number: int
var result: BattleResult

func get_active_player() -> Pokemon:
	return player_party[active_player_index]

func get_active_enemy() -> Pokemon:
	return enemy_party[active_enemy_index]
	
func has_usable_player() -> bool:
	return has_usable(player_party)

func has_usable_enemy() -> bool:
	return has_usable(enemy_party)

func has_usable(party: Array[Pokemon]) -> bool:
	for pokemon in party:
		if pokemon.current_hp > 0:
			return true
	return false

func switch_player_to(index: int) -> void:
	active_player_index = index
	
func switch_enemy_to(index: int) -> void:
	active_enemy_index = index

func is_over() -> bool:
	if result != null:
		return true

	if not has_usable_player():
		return true

	if not has_usable_enemy():
		return true

	return false
