extends RayCast2D
class_name SightRay

@export var distance_tiles: int = 6
@export var auto_scan: bool = true
@export var scan_interval: float = 0.15
@export var trigger_once: bool = true

signal player_spotted(player: Node2D)

var _armed: bool = true
var _accum: float = 0.0

func _ready() -> void:
	_update_sight_ray()
	if not auto_scan:
		set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not auto_scan:
		return
	if not _armed:
		return

	_accum += delta
	if _accum < scan_interval:
		return
	_accum = 0.0

	scan()

func scan() -> void:
	if not _armed:
		return

	_update_sight_ray()
	force_raycast_update()

	if not is_colliding():
		return

	var hit := get_collider()
	while hit:
		if hit is Player:
			_emit_spotted(hit)
			return
		hit = hit.get_parent()

func reset() -> void:
	_armed = true

func disarm() -> void:
	_armed = false

func _emit_spotted(player: Node2D) -> void:
	player_spotted.emit(player)
	if trigger_once:
		_armed = false

func _update_sight_ray() -> void:
	var owner := get_parent()
	if owner == null:
		return

	if not owner.has_method("get") and not ("facing" in owner):
		return

	var facing: Vector2 = owner.facing()
	if facing == Vector2.ZERO:
		return

	target_position = facing.normalized() * float(distance_tiles) * GlobalConstants.tile_size
