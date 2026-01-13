extends PanelContainer
class_name PartyUI

@onready var party_list: VFlowContainer = $"MarginContainer/Party"

@export var party_member_scene: PackedScene 

func _ready() -> void:
	# So this Control can receive unhandled input even if nothing else consumes it
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"): # Esc by default
		visible = false
		# Prevent the escape from also closing other menus underneath
		get_viewport().set_input_as_handled()

func load_party(pokemons: Array) -> void:
	# Clear existing rows
	for child in party_list.get_children():
		child.queue_free()

	# Create one row per pokemon
	for i in pokemons.size():
		var p = pokemons[i]
		if p == null:
			continue

		var row := party_member_scene.instantiate()
		party_list.add_child(row)

		# Optional: keep order stable for navigation/debug
		row.name = "PartyMemberUI_%d" % i

		# Fill the UI
		row.set_pokemon(p)
