extends PanelContainer
class_name PartyUI

signal switch_requested(party_index: int)

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

		var party_member_ui = party_member_scene.instantiate()
		party_member_ui.party_index = i
		party_member_ui.chosen.connect(_party_member_chosen)
		party_list.add_child(party_member_ui)
		party_member_ui.name = "PartyMemberUI_%d" % i
		party_member_ui.set_pokemon(p)

func _party_member_chosen(party_index: int) -> void:
	emit_signal("switch_requested", party_index)
