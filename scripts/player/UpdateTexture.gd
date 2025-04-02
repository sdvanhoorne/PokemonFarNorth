extends Sprite2D

@onready var sprite_up = preload("res://assets/sprites/player/player_up_idle.png")
@onready var sprite_down = preload("res://assets/sprites/player/player_down_idle.png")
@onready var sprite_left = preload("res://assets/sprites/player/player_left_idle.png")
@onready var sprite_right = preload("res://assets/sprites/player/player_right_idle.png")

func update_direction(input: Vector2):
	if input.y == -1:
		texture = sprite_up
	elif input.y == 1:
		texture = sprite_down
	elif input.x == -1:
		texture = sprite_left
	elif input.x == 1:
		texture = sprite_right
