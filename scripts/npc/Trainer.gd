extends CharacterBody2D

class_name Trainer

@onready var sight_ray: SightRay = $SightRay

var is_engaging := false
var has_battled := false
var player_ref: Node2D

func _ready() -> void:
	sight_ray.player_spotted.connect(_on_player_spotted)
	
func facing() -> Vector2:
	return get_node_or_null("CharacterAnimationController").facing

func _on_player_spotted(p: Node2D) -> void:
	if has_battled or is_engaging:
		return

	is_engaging = true
	player_ref = p

	sight_ray.disarm()

	_start_trainer_engage()

func _start_trainer_engage() -> void:
	GameState.lock_gameplay_input()
	# show "!" + walk up + start battle
	# find difference between player and trainer divided by GlobalConstants.tilesize
	# move trainer in that direction, need animation controller 
	
	pass
