extends Node2D
#@onready var HoverTooltip = $PopUpStats
@onready var SpriteArea = $SpriteArea

#func _ready() -> void:
	#SpriteArea.mouse_entered.connect(_on_sprite_area_mouse_entered)
	#SpriteArea.mouse_exited.connect(_on_sprite_area_mouse_exited)
	#HoverTooltip.visible = false

#func _process(_delta):
	#if HoverTooltip.visible:
	#	HoverTooltip.global_position = get_viewport().get_mouse_position()

#func _on_sprite_area_mouse_entered() -> void:
	#HoverTooltip.visible = true
	#var pokemon = get_meta("pokemon")
	#var container = HoverTooltip.get_node("VBoxContainer")
	#container.get_node("Attack").text = "Attack: %d" % pokemon.battle_stats.attack
	#container.get_node("Defense").text = "Defense: %d" % pokemon.battle_stats.defense
	#container.get_node("SpecialAttack").text = "SpecialAttack: %d" % pokemon.battle_stats.special_attack
	#container.get_node("SpecialDefense").text = "SpecialDefense: %d" % pokemon.battle_stats.special_defense
	#container.get_node("Speed").text = "Speed: %d" % pokemon.battle_stats.speed
