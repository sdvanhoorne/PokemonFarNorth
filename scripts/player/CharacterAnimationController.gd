extends AnimatedSprite2D
class_name CharacterAnimationController

var _last_anim := ""

func play_animation(move_state: String, facing_direction: String) -> void:
	if not GameState.gameplay_input_enabled:
		return
	var animation_name = move_state + "_" + facing_direction
	if animation_name == _last_anim:
		return
	_last_anim = animation_name
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		return
	play(animation_name)
