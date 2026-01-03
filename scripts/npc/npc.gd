extends CharacterBody2D

@export var npc_id: String = "default_npc"
@export var dialogue_file: String = "res://data/npcs/npcs.json"

@onready var sprite = $AnimatedSprite2D
@onready var interactable: Interactable = $Interactable

var Movement = null

func _ready():
	Movement = MovementController.new(self)

func on_talk(player: Node) -> void:
	face_toward(player.global_position)
	await DialogueManager.start_dialogue(load_dialogue_from_file())

func load_dialogue_from_file() -> PackedStringArray:
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and npc_id in data:
			return data[npc_id]
	return ["Couldn't find dialogue for npc"]
			
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
