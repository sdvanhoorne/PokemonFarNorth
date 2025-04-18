class_name Move

var Name = ""
var Damage = 0
var Type = ""
var Category = ""
var Target = ""
var Target_Stat = ""
var Stat_Multiplier = 1.0
var Accuracy = 1.0
var Description = ""

func _init(name: String, moveData = {}):
	Name = name
	Damage = moveData.get("Damage")
	Type = moveData.get("Type")
	Target = moveData.get("Target")
	Target_Stat = moveData.get("Target_Stat")
	Stat_Multiplier = moveData.get("Stat_Multiplier")
	Category = moveData.get("Category")
	Accuracy = moveData.get("Accuracy")
	Description = moveData.get("Description")
