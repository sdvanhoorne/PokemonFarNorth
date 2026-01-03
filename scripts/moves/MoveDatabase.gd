extends Node

var moves : Array = []

func _ready():
	# Load and parse the JSON file once at startup
	var file := FileAccess.open("res://data/moves/moves.json", FileAccess.READ)
	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_ARRAY:
		moves = parsed

func get_move_by_name(move_name: String) -> Move:
	for move in moves:
		if move.has("name") and move["name"] == move_name:
			return Move.new(move)
	return Move.new({})
