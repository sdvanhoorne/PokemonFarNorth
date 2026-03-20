extends Node
class_name MovementController

signal moved_to_tile(new_global_pos: Vector2)

@export var body_path: NodePath
@export var hold_threshold: float = 0.03
@export var sprint_multiplier: float = 2.25

@onready var body: CharacterBody2D = get_node(body_path)

var facing_input := Vector2.ZERO
var facing_direction := "down"
var facing := Vector2.ZERO

var is_moving := false
var target_position := Vector2.ZERO
var hold_timer := 0.0
var sprinting := false

var move_direction := Vector2.ZERO
var move_facing_direction := "down"
var move_sprinting := false

func snap_to_grid() -> void:
	body.global_position = body.global_position.snapped(Vector2(GlobalConstants.tile_size, GlobalConstants.tile_size))
	target_position = body.global_position

func get_animation_direction() -> String:
	if is_moving:
		return move_facing_direction
	return facing_direction

func set_desired_input(dir: Vector2, want_sprint: bool) -> void:
	sprinting = want_sprint

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		facing = dir

		if not is_moving:
			_update_facing_direction_from_vector(dir)

		if dir != facing_input:
			facing_input = dir
			hold_timer = 0.0

func tick(delta: float) -> void:
	if is_moving:
		_continue_move(delta)
		return

	if facing_input == Vector2.ZERO or not GameState.gameplay_input_enabled:
		hold_timer = 0.0
		body.velocity = Vector2.ZERO
		return

	hold_timer += delta
	if hold_timer >= hold_threshold:
		hold_timer = 0.0
		_try_start_step(facing_input, sprinting)

func _try_start_step(dir: Vector2, want_sprint: bool) -> bool:
	var offset := dir * GlobalConstants.tile_size
	if body.test_move(body.global_transform, offset):
		return false

	target_position = body.global_position + offset
	is_moving = true
	move_direction = dir
	move_facing_direction = _direction_to_name(dir)
	move_sprinting = want_sprint
	return true
	
func _direction_to_name(v: Vector2) -> String:
	if v.x > 0.0:
		return "right"
	elif v.x < 0.0:
		return "left"
	elif v.y > 0.0:
		return "down"
	else:
		return "up"

func stop() -> void:
	is_moving = false
	body.velocity = Vector2.ZERO

func get_move_state() -> String:
	if is_moving:
		return "sprint" if move_sprinting else "move"

	if facing_input != Vector2.ZERO:
		return "sprint" if sprinting else "move"

	return "idle"

func clear_input() -> void:
	facing_input = Vector2.ZERO
	hold_timer = 0.0

func _continue_move(delta: float) -> void:
	var speed := GlobalConstants.tile_size / GlobalConstants.move_time
	if move_sprinting:
		speed *= sprint_multiplier

	var to_target := target_position - body.global_position
	var distance_this_frame := speed * delta

	if to_target.length() <= distance_this_frame:
		body.global_position = target_position
		body.velocity = Vector2.ZERO
		is_moving = false

		# Promote the completed move direction to the idle facing.
		facing_direction = move_facing_direction

		move_direction = Vector2.ZERO
		move_sprinting = false
		emit_signal("moved_to_tile", body.global_position)

		if facing_input != Vector2.ZERO and GameState.gameplay_input_enabled:
			_try_start_step(facing_input, sprinting)

		return

	body.velocity = to_target.normalized() * speed
	body.move_and_slide()

func _update_facing_direction_from_vector(v: Vector2) -> void:
	facing_direction = _direction_to_name(v)

func request_step(dir: Vector2, want_sprint: bool = false) -> bool:
	if is_moving:
		return false
	if dir == Vector2.ZERO:
		return false

	set_desired_input(dir, want_sprint)
	hold_timer = hold_threshold
	tick(0.0)

	if is_moving:
		clear_input()

	return is_moving
