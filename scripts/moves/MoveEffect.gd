class_name MoveEffect
extends RefCounted

var kind: String
var target: String
var stat: String
var stages: int
var chance: int

func _init(
	p_kind: String,
	p_target: String,
	p_stat: String,
	p_stages: int,
	p_chance: int = 100
) -> void:
	kind = p_kind
	target = p_target
	stat = p_stat
	stages = p_stages
	chance = p_chance
