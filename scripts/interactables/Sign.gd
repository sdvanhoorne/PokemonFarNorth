@tool
extends Interactable
class_name Sign

@export_multiline var text: String = "..."

@export var sign_texture: Texture2D:
	set(value):
		sign_texture = value
		if is_instance_valid(sprite):
			sprite.texture = sign_texture

@onready var sprite: Sprite2D = $Sprite2D

func _do_interact(_player: Node) -> void:
	await DialogueManager.start_dialogue([text])
