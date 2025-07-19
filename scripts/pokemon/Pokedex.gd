# Pokedex.gd (autoloaded singleton)
extends Node

var pokedex_file := [] # Array of dictionaries
var pokedex := {} # Map from ID to name

func _ready():
	var file = FileAccess.open("res://data/pokedex.json", FileAccess.READ)
	pokedex_file = JSON.parse_string(file.get_as_text())
	for entry in pokedex:
		pokedex[entry.id] = entry.name
