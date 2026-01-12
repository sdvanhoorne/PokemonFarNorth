extends CharacterBody2D

@export var npc_id: String = "default_npc"
@export var dialogue_file: String = "res://data/npcs/npcs.json"

@onready var anim: CharacterAnimationController = $CharacterAnimationController
@onready var interactable: Interactable = $Interactable

var Movement = null

func _ready():
	Movement = MovementController.new(self)
	anim.set_facing(Vector2.DOWN) # default

func on_talk(player: Node) -> void:
	anim.set_facing(player.global_position - global_position)
	anim.play_idle()
	await DialogueManager.say(load_dialogue_from_file(),{
		"lock_input": false,
		"require_input": true
	})

func load_dialogue_from_file() -> PackedStringArray:
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and npc_id in data:
			return data[npc_id]
	return ["Couldn't find dialogue for npc"]
