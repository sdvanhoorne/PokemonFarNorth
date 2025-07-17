extends CharacterBody2D

@export var npc_id: String = "default_npc"
@export var dialogue_file: String = "res://data/npcs.json"

@onready var interaction_area = $Area2D
@onready var sprite = $AnimatedSprite2D

var player_in_range = false
var player_ref: Node2D = null
var dialogue_lines = []
var showing_dialogue = false
var Movement = null
var message_box: Node

func _ready():
	Movement = MovementController.new(self)
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	load_dialogue_from_file()
	message_box = get_node_or_null("/root/World/CanvasLayer/MessageBox")

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null
		DialogueManager.hide_dialogue_box()

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_in_range and player_ref:
		if showing_dialogue:
			DialogueManager.hide_dialogue_box()
			showing_dialogue = false
		else:
			face_toward(player_ref.global_position)
			showing_dialogue = true
			DialogueManager.print_lines(message_box, dialogue_lines)

func start_dialogue():
	for line in dialogue_lines:
		print(line) 

func load_dialogue_from_file():
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and npc_id in data:
			dialogue_lines = data[npc_id]
			
func face_toward(target_position: Vector2):
	var direction = (target_position - global_position).normalized()

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play("Move_Right")
		else:
			sprite.play("Move_Left")
	else:
		if direction.y > 0:
			sprite.play("Move_Down")
		else:
			sprite.play("Move_Up")
	sprite.stop()
