# MovementController.gd (could be a Node or Resource)
class_name MovementController
extends Node

const TILE_SIZE = 16
const MOVE_TIME = 0.12  # Time it takes to move one tile
var sprint_multipier = 1.75

var character

func _init(c: CharacterBody2D):
	character = c
	character.global_position = character.global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) 

func move_to_target(target_position: Vector2, speed: float, sprinting: bool):
	var direction = (target_position - character.global_position).normalized()
	character.velocity = direction * (TILE_SIZE / MOVE_TIME)
	if(sprinting):
		character.velocity = character.velocity * sprint_multipier
	character.move_and_slide()
