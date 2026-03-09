extends CanvasLayer

@onready var entry_list: VBoxContainer = $"Root/HBoxContainer/ListPanel/MarginContainer/ScrollContainer/VerticalListContainer"
@onready var pokedex_path = Paths.POKEDEX_ROOT + "/pokedex.json"

@onready var name_label: Label = $Root/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/HeaderRow/NameLabel
@onready var number_label: Label = $Root/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/HeaderRow/NumberLabel
@onready var description_label: Label = $Root/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var pokemon_sprite: TextureRect = $Root/HBoxContainer/DetailPanel/MarginContainer/VBoxContainer/SpriteContainer/PokemonSprite


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
	var pokemon = get_pokemon_data(pokemon_id)
	update_detail_panel(pokemon)
	
func get_pokemon_data(pokemon_id: int) -> Dictionary:
	for pokemon in pokemon_data:
		if pokemon.id == pokemon_id:
			return pokemon
	return {}
	
func update_detail_panel(pokemon: Dictionary) -> void:
	var x = 1
	#number_label.text = "#%03d" % pokemon.id
	#name_label.text = pokemon.name
	#description_label.text = pokemon.description
	#pokemon_sprite.texture = load(pokemon.sprite_path)
