extends CharacterBody2D
class_name Npc

@export var npc_id: String = "default_npc"
@export var dialogue_file: String = "res://data/npcs/npcs.json"
@export var sprite_frames: SpriteFrames

@onready var character_animation_controller: CharacterAnimationController = $CharacterAnimationController
@onready var movement_controller: MovementController = $MovementController
@onready var wander_controller: WanderController = $WanderController
@onready var interactable: Interactable = $Interactable

var Movement = null

func _ready():
	character_animation_controller.sprite_frames = sprite_frames
	movement_controller._update_facing_direction_from_vector(Vector2.DOWN) 
	movement_controller.snap_to_grid()
	
func _physics_process(delta: float) -> void:
	movement_controller.tick(delta)
	
	# Animation
	var state := movement_controller.get_move_state()
	var facing_direction := movement_controller.facing_direction
	if(state == "move"):
		var test = 1
	character_animation_controller.play_animation(state, facing_direction)

func on_talk(player: Node) -> void:
	wander_controller.enabled = false
	movement_controller._update_facing_direction_from_vector(player.global_position - global_position)
	character_animation_controller.play_animation(movement_controller.get_move_state(), movement_controller.facing_direction)
	await DialogueManager.say(load_dialogue_from_file(),{
		"lock_input": true,
		"require_input": true
	})
	wander_controller.enabled = true

func load_dialogue_from_file() -> PackedStringArray:
	var file = FileAccess.open(dialogue_file, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and npc_id in data:
			return data[npc_id]
	return ["Couldn't find dialogue for npc"]
