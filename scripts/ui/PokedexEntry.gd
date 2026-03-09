extends Control

signal hovered_pokemon(pokemon_id: int)

@onready var button: Button = $Button
var pokemon_id: int
var pokemon_name: String = ""

func _ready() -> void:
	custom_minimum_size.y = 24
	button.add_theme_font_size_override("font_size", 14)
	button.text = "%03d  %s" % [pokemon_id, pokemon_name]
	button.mouse_entered.connect(_on_mouse_entered)
	button.focus_entered.connect(_on_focus_entered)

func setup(id: int, name: String) -> void:
	pokemon_id = id
	pokemon_name = name
	
func _on_mouse_entered() -> void:
	hovered_pokemon.emit(pokemon_id)

func _on_focus_entered() -> void:
	hovered_pokemon.emit(pokemon_id)
