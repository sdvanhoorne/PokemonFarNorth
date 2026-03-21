extends CharacterBody2D
class_name Npc

@onready var character_animation_controller: CharacterAnimationController = $CharacterAnimationController
@onready var movement_controller: MovementController = $MovementController
@onready var wander_controller: WanderController = $WanderController
@onready var interactable: Interactable = $Interactable

@export var npc_id: String = "default_npc_id"
@export var sprite_frames: SpriteFrames
@export var wander: bool = false

var npc_name: String = "default_npc_name"
var dialogue: Dictionary = {}

func _ready():
	_load_npc_data()
	character_animation_controller.sprite_frames = sprite_frames
	movement_controller._update_facing_direction_from_vector(Vector2.DOWN) 
	movement_controller.snap_to_grid()
	
func _physics_process(delta: float) -> void:
	movement_controller.tick(delta)
	
	# Animation
	var state := movement_controller.get_move_state()
	var facing_direction := movement_controller.facing_direction
	character_animation_controller.play_animation(state, facing_direction)

func on_talk(player: Node) -> void:
	wander_controller.enabled = false
	movement_controller._update_facing_direction_from_vector(player.global_position - global_position)
	character_animation_controller.play_animation(movement_controller.get_move_state(), movement_controller.facing_direction)
	await DialogueManager.say(dialogue["default"],{
		"lock_input": true,
		"require_input": true
	})
	wander_controller.enabled = true

func _load_npc_data() -> void:
	var data = NpcDatabase.get_npc_data(npc_id)
	dialogue = data.get("dialogue", {})

func _get_dialogue(dialogue_key: String = "default") -> Array[String]:
	var result: Array[String] = []

	if not dialogue.has(dialogue_key):
		return result

	var lines: Array = dialogue[dialogue_key]
	for line in lines:
		result.append(str(line))

	return result
