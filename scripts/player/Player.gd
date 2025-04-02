extends CharacterBody2D
@onready var visuals = $Sprite2D

const TILE_SIZE = 16
const MOVE_TIME = 0.1  # Time it takes to move one tile
var facing_input = Vector2.ZERO
var hold_timer = 0.0
const HOLD_THRESHOLD = 0.03
var is_moving = false
var target_position = Vector2.ZERO

func _ready():
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) # ✅ Ensure alignment
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		# Continue moving toward target
		var direction = (target_position - global_position).normalized()
		velocity = direction * (TILE_SIZE / MOVE_TIME)
		move_and_slide()

		if global_position.distance_to(target_position) < 1:
			global_position = target_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
			is_moving = false
			velocity = Vector2.ZERO
			check_for_grass_encounter()
		return

	var input = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input.y -= 1
	elif Input.is_action_pressed("ui_down"):
		input.y += 1
	elif Input.is_action_pressed("ui_left"):
		input.x -= 1
	elif Input.is_action_pressed("ui_right"):
		input.x += 1

	if input != Vector2.ZERO:
		input = input.normalized()
		
		# If new direction is different, update facing direction instantly
		if input != facing_input:
			facing_input = input
			hold_timer = 0.0
			visuals.update_direction(facing_input)
		else:
			hold_timer += delta
			if hold_timer >= HOLD_THRESHOLD:
				var offset = input * TILE_SIZE
				if !test_move(global_transform, offset):
					target_position = global_position + offset
					is_moving = true
	else:
		# Reset if no direction held
		facing_input = Vector2.ZERO
		hold_timer = 0.0

func check_for_grass_encounter():
	var tilemap = get_tree().current_scene.get_node("RandomEncounterLayer")
	
	if tilemap == null:
		return

	var local_pos = tilemap.to_local(global_position)
	var cell_coords = tilemap.local_to_map(local_pos)
	var tile_data = tilemap.get_cell_tile_data(cell_coords)

	if tile_data == null:
		return # No tile here, early exit

	if tile_data.get_custom_data("encounter_grass") != true:
		return # Not a grass tile

	# Only gets here if tile is grass
	if randf() < 0.1:
		print("A wild battle begins!")
		#get_tree().change_scene_to_file("res://scenes/battles/battle.tscn")
