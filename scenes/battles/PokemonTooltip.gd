extends Node2D
@onready var HoverTooltip = $PopUpStats

func _process(_delta):
	if HoverTooltip.visible:
		HoverTooltip.global_position = get_viewport().get_mouse_position()

func _on_sprite_area_mouse_entered() -> void:
	var pokemon = get_meta("pokemon")
	var container = HoverTooltip.get_node("VBoxContainer")
	container.get_node("Attack").text = "Attack: %d" % pokemon.BattleStats.Attack
	container.get_node("Defense").text = "Defense: %d" % pokemon.BattleStats.Defense
	container.get_node("SpecialAttack").text = "SpecialAttack: %d" % pokemon.BattleStats.Special_Attack
	container.get_node("SpecialDefense").text = "SpecialDefense: %d" % pokemon.BattleStats.Special_Defense
	container.get_node("Speed").text = "Speed: %d" % pokemon.BattleStats.Speed
	HoverTooltip.visible = true

func _on_sprite_area_mouse_exited() -> void:
	HoverTooltip.visible = false
