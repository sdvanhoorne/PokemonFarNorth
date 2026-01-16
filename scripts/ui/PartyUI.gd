extends PanelContainer
class_name PartyUI

@onready var party_list: VFlowContainer = $"MarginContainer/Party"

@export var party_member_scene: PackedScene 

func _ready() -> void:
	set_process_unhandled_input(true)

func load_party(pokemons: Array) -> void:
	for child in party_list.get_children():
		child.queue_free()

	for i in pokemons.size():
		var p = pokemons[i]
		if p == null:
			continue

		var row := party_member_scene.instantiate()
		party_list.add_child(row)
		row.name = "PartyMemberUI_%d" % i
		row.set_pokemon(p)
