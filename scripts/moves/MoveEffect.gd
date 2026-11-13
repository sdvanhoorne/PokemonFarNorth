class_name MoveEffect
extends RefCounted

var kind: String
var target: String
var stat: String
var stages: int
var chance: int
var status: String

func _init(
	p_kind: String,
	p_target: String,
	p_stat: String,
	p_stages: int,
	p_chance: int = 100,
	p_status: String = ""
) -> void:
	kind = p_kind
	target = p_target
	stat = p_stat
	stages = p_stages
	chance = p_chance
	status = p_status
