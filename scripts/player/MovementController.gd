# GridMover.gd
extends Node
class_name MovementController

signal step_finished()
signal step_started()
signal blocked(dir: Vector2)

@export var tile_size: int = 16
@export var move_time: float = 0.18
@export var sprint_multiplier: float = 2.0

var is_moving := false
var target_position: Vector2
var facing := Vector2.DOWN
var sprinting := false

var _actor: CharacterBody2D

func _ready() -> void:
	_actor = get_parent() as CharacterBody2D
	assert(_actor != null, "GridMover must be a child of a CharacterBody2D")
	_actor.global_position = _actor.global_position.snapped(Vector2(tile_size, tile_size))
	target_position = _actor.global_position

func physics_tick(delta: float) -> void:
	if not is_moving:
		_actor.velocity = Vector2.ZERO
		return

	var dir := (target_position - _actor.global_position).normalized()
	var speed := float(tile_size) / move_time
	if sprinting:
		speed *= sprint_multiplier

	_actor.velocity = dir * speed
	_actor.move_and_slide()

	# Snap when close enough (your original threshold logic, simplified)
	if _actor.global_position.distance_to(target_position) <= speed * delta + 0.01:
		_actor.global_position = target_position.snapped(Vector2(tile_size, tile_size))
		_actor.velocity = Vector2.ZERO
		is_moving = false
		step_finished.emit()

func face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	facing = dir.normalized()

func request_step(dir: Vector2) -> bool:
	# returns true if step started
	if is_moving:
		return false
	if dir == Vector2.ZERO:
		return false

	dir = dir.normalized()
	face(dir)

	var offset := dir * tile_size

	# IMPORTANT: test_move expects a Transform2D + motion vector
	if _actor.test_move(_actor.global_transform, offset):
		blocked.emit(dir)
		return false

	target_position = _actor.global_position + offset
	is_moving = true
	step_started.emit()
	return true

func queue_steps(dirs: Array[Vector2]) -> void:
	# Fire-and-forget straight-line stepping
	# (Trainer can await step_finished in a loop too, if you prefer.)
	_call_queue_steps(dirs)

func _call_queue_steps(dirs: Array[Vector2]) -> void:
	# Run sequentially without blocking caller
	_run_queue_steps.call_deferred(dirs)

func _run_queue_steps(dirs: Array[Vector2]) -> void:
	for d in dirs:
		while is_moving:
			await step_finished
		var ok := request_step(d)
		if not ok:
			return
		await step_finished
