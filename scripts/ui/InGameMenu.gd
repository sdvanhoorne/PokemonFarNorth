extends CanvasLayer

func open() -> void:
	visible = true
	# grab focus on first enabled button
	$Control/MarginContainer/PanelContainer/VBoxContainer/PokedexContainer/Button.grab_focus()

func close() -> void:
	visible = false

func _on_pokemon_pressed() -> void:
	visible = false
