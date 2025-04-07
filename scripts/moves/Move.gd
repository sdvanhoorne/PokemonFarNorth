class_name Move

var damage = 0
var type = ""
var category = ""
var accuracy = 1
var description = ""

func _init(moveData = {}):
	damage = moveData.get("damage")
	type = moveData.get("type")
	category = moveData.get("category")
	accuracy = moveData.get("accuracy")
	# description = moveData.get("description")
