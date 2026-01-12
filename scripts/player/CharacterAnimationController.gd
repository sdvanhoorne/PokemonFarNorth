extends AnimatedSprite2D
class_name CharacterAnimationController

@export var sprite_path: NodePath = ^"../AnimatedSprite2D"

# If your animations are Move_Up/Down/Left/Right and you call stop() for idle,
# keep these prefixes.
@export var move_prefix: String = "Move_"
# Optional if you later add real idle animations like Idle_Up, etc.
@export var idle_prefix: String = "Idle_" # set to "Idle_" if you create those

@export var speed_threshold: float = 1.0 # how fast before we count as "moving"

var facing: Vector2 = Vector2.DOWN
var _is_moving: bool = false


func set_facing(dir: Vector2) -> void:
	var c := _to_cardinal(dir)
	if c != Vector2.ZERO:
		facing = c
	_update_animation()


func set_velocity(vel: Vector2) -> void:
	# Decide if moving + update facing when moving
	_is_moving = vel.length() > speed_threshold
	if _is_moving:
		set_facing(vel) # updates facing + animation
	else:
		_update_animation()


func play_idle() -> void:
	_is_moving = false
	_update_animation()


func play_move(dir: Vector2) -> void:
	_is_moving = true
	set_facing(dir)


func _update_animation() -> void:
	var dir_name := _dir_name(facing)

	if _is_moving:
		var anim := move_prefix + dir_name
		if sprite_frames and sprite_frames.has_animation(anim):
			play(anim)
		else:
			# fallback: try without prefix (in case naming differs)
			if sprite_frames and sprite_frames.has_animation(dir_name):
				play(dir_name)
	else:
		# If you don’t have idle animations, emulate idle by stopping on the move anim frame.
		if idle_prefix != "":
			var idle_anim := idle_prefix + dir_name
			if sprite_frames and sprite_frames.has_animation(idle_anim):
				play(idle_anim)
				return

		var move_anim := move_prefix + dir_name
		if sprite_frames and sprite_frames.has_animation(move_anim):
			play(move_anim)
			stop()


func _to_cardinal(v: Vector2) -> Vector2:
	if v == Vector2.ZERO:
		return Vector2.ZERO
	var d := v.normalized()
	if abs(d.x) > abs(d.y):
		return Vector2.RIGHT if d.x > 0.0 else Vector2.LEFT
	else:
		return Vector2.DOWN if d.y > 0.0 else Vector2.UP


func _dir_name(cardinal: Vector2) -> String:
	if cardinal == Vector2.RIGHT: return "Right"
	if cardinal == Vector2.LEFT:  return "Left"
	if cardinal == Vector2.UP:    return "Up"
	return "Down"
