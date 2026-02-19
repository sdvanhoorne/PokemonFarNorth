extends AnimatedSprite2D
class_name CharacterAnimationController

var _last_anim := ""

func play_animation(move_state: String, facing_direction: String) -> void:
	var name = move_state + "_" + facing_direction
	if name == _last_anim:
		return
	_last_anim = name
	if sprite_frames == null or not sprite_frames.has_animation(name):
		return
	print(name)
	play(name)
