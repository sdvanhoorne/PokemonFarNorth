extends Node2D
class_name WanderController

@export var movement_controller_path: NodePath
@onready var move: MovementController = get_node(movement_controller_path)

@export_range(0, 50, 1) var max_distance_tiles: int = 4
@export var min_wait: float = 0.8
@export var max_wait: float = 2.2
@export_range(0.0, 1.0, 0.05) var idle_chance: float = 0.25
@export_range(0.0, 1.0, 0.05) var bias_toward_home: float = 0.65

var enabled: bool = false
var _spawn_tile: Vector2i
var _rng := RandomNumberGenerator.new()
var _timer := 0.0
var _next_time := 1.0

func _ready() -> void:
	enabled = get_parent().wander
	_rng.randomize()

	# Assumes NPC is already snapped to grid (or close enough)
	var p := move.body.global_position
	_spawn_tile = _world_to_tile(p)

	_schedule_next()

func _physics_process(delta: float) -> void:
	if not enabled:
		return

	# Let committed movement finish untouched.
	if move.is_moving:
		return

	_timer += delta
	if _timer < _next_time:
		return

	_timer = 0.0
	_schedule_next()

	if _rng.randf() < idle_chance:
		move.clear_input()
		return

	var dir := _choose_step_dir()
	if dir != Vector2.ZERO:
		var started := move.request_step(dir, false)
		if not started:
			move.clear_input()
	else:
		move.clear_input()

func _schedule_next() -> void:
	_next_time = _rng.randf_range(min_wait, max_wait)

func _choose_step_dir() -> Vector2:
	var current_tile := _world_to_tile(move.body.global_position)
	var delta := current_tile - _spawn_tile
	var dist = max(abs(delta.x), abs(delta.y)) 

	# Hard clamp: if we're at/over max, move toward home (if possible)
	if dist >= max_distance_tiles:
		return _step_toward_home(delta)

	# Soft bias near the edge
	if dist >= max_distance_tiles - 1 and _rng.randf() < bias_toward_home:
		var toward := _step_toward_home(delta)
		if toward != Vector2.ZERO:
			return toward

	# Otherwise random valid direction
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	dirs.shuffle()
	for d in dirs:
		if _can_step(d):
			return d

	return Vector2.ZERO

func _step_toward_home(delta: Vector2i) -> Vector2:
	var options: Array[Vector2] = []

	if delta.x > 0:
		options.append(Vector2.LEFT)
	elif delta.x < 0:
		options.append(Vector2.RIGHT)

	if delta.y > 0:
		options.append(Vector2.UP)
	elif delta.y < 0:
		options.append(Vector2.DOWN)

	options.shuffle()
	for d in options:
		if _can_step(d):
			return d

	# If blocked, try any direction
	var dirs := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	dirs.shuffle()
	for d in dirs:
		if _can_step(d):
			return d

	return Vector2.ZERO

func _can_step(dir: Vector2) -> bool:
	var offset := dir * GlobalConstants.tile_size
	return not move.body.test_move(move.body.global_transform, offset)

func _world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(
		round(pos.x / GlobalConstants.tile_size),
		round(pos.y / GlobalConstants.tile_size)
	)
