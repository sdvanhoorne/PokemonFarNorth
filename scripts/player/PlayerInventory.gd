extends Node

var pokemon = []
const party_path = "res://data/player/party.json"

func _ready():
	var party = FileAccess.open(party_path, FileAccess.READ)
	if party:
		pokemon = JSON.parse_string(party.get_as_text())["party"]

func get_lead():
	return pokemon[0]
