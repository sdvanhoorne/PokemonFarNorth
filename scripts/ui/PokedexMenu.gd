extends CanvasLayer

@onready var entry_list: VBoxContainer = $"Root/HBoxContainer/ListPanel/MarginContainer/ScrollContainer/VerticalListContainer"
@onready var pokedex_path = Paths.POKEDEX_ROOT + "/pokedex.json"

@onready var name_label: Label = $Root/HBoxContainer/InfoPanel/MarginContainer/VBoxContainer/Label
@onready var type1_control: Control = $Root/HBoxContainer/InfoPanel/MarginContainer/VBoxContainer/HBoxContainer/Type1
@onready var type2_control: Control = $Root/HBoxContainer/InfoPanel/MarginContainer/VBoxContainer/HBoxContainer/Type2
@onready var pokemon_sprite: TextureRect = $Root/HBoxContainer/InfoPanel/MarginContainer/VBoxContainer/Control/CenterContainer/TextureRect


var pokedex_entry_scene := preload("res://scenes/ui/PokedexEntry.tscn")
var pokemon_data: Array = []

func load_pokemon_list() -> void:
	var file := FileAccess.open(pokedex_path, FileAccess.READ)
	var json_text := file.get_as_text()
	var pokemon_data = JSON.parse_string(json_text)
	
	for pokemon in pokemon_data:
		var entry = pokedex_entry_scene.instantiate()
		entry.pokemon_id = pokemon.id
		entry.setup(pokemon.id, pokemon.name)
		entry.hovered_pokemon.connect(_on_entry_hovered)
		entry_list.add_child(entry)
		
func _on_entry_hovered(pokemon_id: int) -> void:
	var pokemon_base_data = PokemonBase.new(pokemon_id)
	_update_detail_panel(pokemon_base_data)
	
func _update_detail_panel(pokemon: PokemonBase) -> void:
	name_label.text = pokemon.name
	
	_set_type_control(type1_control, pokemon.type1)
	_set_type_control(type2_control, pokemon.type2)
	
	pokemon_sprite.texture = pokemon.sprite
	
func _set_type_control(type_control: Control, type: String) -> void:
	if type == null or type.is_empty():
		type_control.visible = false
		return
	type_control.visible = true
	var label = type_control.get_node("Label")
	var color_rect = type_control.get_node("ColorRect")
	
	label.text = type
	var background_color = TypeColors.color_for(type)
	var font_color = TypeColors.font_color_for(type)
	color_rect.color = background_color
	label.add_theme_color_override("font_color", font_color)
