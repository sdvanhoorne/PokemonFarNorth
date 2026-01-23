extends Node

const TYPE_COLOR: Dictionary = {
	&"normal":   Color("#A8A77A"),
	&"fire":     Color("#ea7a3c"),
	&"water":    Color("#6390F0"),
	&"electric": Color("#F7D02C"),
	&"grass":    Color("#7AC74C"),
	&"ice":      Color("#96D9D6"),
	&"fighting": Color("#C22E28"),
	&"poison":   Color("#A33EA1"),
	&"ground":   Color("#E2BF65"),
	&"flying":   Color("#A98FF3"),
	&"psychic":  Color("#F95587"),
	&"bug":      Color("#A6B91A"),
	&"rock":     Color("#B6A136"),
	&"ghost":    Color("#735797"),
	&"dragon":   Color("#6F35FC"),
	&"dark":     Color("#705746"),
	&"steel":    Color("#B7B7CE"),
	&"fairy":    Color("#D685AD"),
}

const DEFAULT_COLOR := Color.WHITE

static func color_for(type_name: StringName) -> Color:
	var key := type_name
	if not TYPE_COLOR.has(key):
		key = StringName(String(type_name).to_lower())
	return TYPE_COLOR.get(key, DEFAULT_COLOR)
