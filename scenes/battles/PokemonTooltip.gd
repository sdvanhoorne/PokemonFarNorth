extends Node2D
@onready var HoverTooltip = $PopUpStats

func _process(delta):
	if $PopUpStats.visible:
		$PopUpStats.position = get_viewport().get_mouse_position()

func _on_sprite_area_mouse_entered() -> void:
	var pokemon = get_meta("pokemon")
	var container = $PopUpStats.get_node("VBoxContainer")
	container.get_node("Attack").text = "Attack: %d" % pokemon.attack
	container.get_node("Defense").text = "Defense: %d" % pokemon.defense
	container.get_node("SpecialAttack").text = "SpecialAttack: %d" % pokemon.special_attack
	container.get_node("SpecialDefense").text = "SpecialDefense: %d" % pokemon.special_defense
	container.get_node("Speed").text = "Speed: %d" % pokemon.speed
	$PopUpStats.visible = true

func _on_sprite_area_mouse_exited() -> void:
	$PopUpStats.visible = false
