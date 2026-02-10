extends CharacterBody2D

class_name Trainer

@onready var sight_ray: SightRay = $SightRay
@onready var alert_animation: AnimatedSprite2D = $Sprites/AlertAnimation

var is_engaging := false
var has_battled := false
var player_ref: Node2D

func _ready() -> void:
	sight_ray.player_spotted.connect(_on_player_spotted)
	
func facing() -> Vector2:
	return get_node_or_null("Sprites/CharacterAnimationController").facing

func _on_player_spotted(p: Node2D) -> void:
	if has_battled or is_engaging:
		return

	is_engaging = true
	player_ref = p

	# sight_ray.disarm()

	_start_trainer_engage()

func _start_trainer_engage() -> void:
	GameState.lock_gameplay_input()
	# show "!" + walk up + start battle
	play_alert()
	is_engaging = false
	# find difference between player and trainer divided by GlobalConstants.tilesize
	# move trainer in that direction, need animation controller 
	
	pass

func play_alert():
	alert_animation.visible = true
	
	alert_animation.play("alert") 

	var end_pos := Vector2(0, -24)     # where it should land (relative to trainer)
	var start_pos := end_pos + Vector2(0, -16)

	alert_animation.position = start_pos
	alert_animation.modulate.a = 1.0

	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(alert_animation, "position", end_pos, 0.18)

	# little bounce / settle
	t.tween_property(alert_animation, "position", end_pos + Vector2(0, 2), 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(alert_animation, "position", end_pos, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# hide after a moment
	t.tween_interval(0.4)
	t.tween_property(alert_animation, "modulate:a", 0.0, 0.12)
	t.tween_callback(func(): alert_animation.visible = false)
