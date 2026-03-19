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

func set_desired_input(dir: Vector2, want_sprint: bool) -> void:
	sprinting = want_sprint

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		facing = dir
		_update_facing_direction_from_vector(dir)

		if dir != facing_input:
			facing_input = dir
			hold_timer = 0.0

func tick(delta: float) -> void:
	if is_moving:
		_continue_move(delta)
		return

	# no input held
	if facing_input == Vector2.ZERO or not GameState.gameplay_input_enabled:
		hold_timer = 0.0
		return

	# input held, count hold time and step when threshold reached
	hold_timer += delta
	if hold_timer >= hold_threshold:
		hold_timer = 0.0
		var offset := facing_input * GlobalConstants.tile_size
		if not body.test_move(body.global_transform, offset):
			target_position = body.global_position + offset
			is_moving = true
			move_direction = facing_input
			move_facing_direction = facing_direction
			move_sprinting = sprinting

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
	var dir := (target_position - body.global_position).normalized()
	body.velocity = dir * (GlobalConstants.tile_size / GlobalConstants.move_time)
	if move_sprinting:
		body.velocity *= sprint_multiplier

	body.move_and_slide()

	if body.global_position.distance_to(target_position) <= body.velocity.length() * get_physics_process_delta_time():
		body.global_position = target_position
		is_moving = false
		body.velocity = Vector2.ZERO
		move_direction = Vector2.ZERO
		move_sprinting = false
		emit_signal("moved_to_tile", body.global_position)

func _update_facing_direction_from_vector(v: Vector2) -> void:
	if v.x > 0.0:
		facing_direction = "right"
	elif v.x < 0.0:
		facing_direction = "left"
	elif v.y > 0.0:
		facing_direction = "down"
	else:
		facing_direction = "up"
		
func request_step(dir: Vector2, want_sprint: bool = false) -> bool:
	if is_moving:
		return false
	if dir == Vector2.ZERO:
		return false

	set_desired_input(dir, want_sprint)
	hold_timer = hold_threshold
	tick(0.0)

	# This was an AI-requested single step, not held input.
	# Keep the committed move going, but prevent chaining more steps.
	if is_moving:
		clear_input()

	return is_moving
