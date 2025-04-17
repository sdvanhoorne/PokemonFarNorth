extends CharacterBody2D

@export var npc_id: String = "default_npc"
@export var dialogue_file: String = "res://data/npcs.json"

@onready var interaction_area = $Area2D

var player_in_range = false
var dialogue_lines = []
var Movement = null

func _ready():
	Movement = MovementController.new(self)
	#interaction_area.body_entered.connect(_on_body_entered)
	#interaction_area.body_exited.connect(_on_body_exited)
	load_dialogue_from_file()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range:
		start_dialogue()

func start_dialogue():
	for line in dialogue_lines:
		print(line)  # Replace this with actual dialogue UI handling

func load_dialogue_from_file():
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and npc_id in data:
			dialogue_lines = data[npc_id]
