class_name MoveTag

enum Type {
	CONTACT,
	PROJECTILE,
	BITE,
	PUNCH,
	SOUND
}


static func from_string(value: String) -> Type:
	match value.to_upper():
		"CONTACT":
			return Type.CONTACT
		"PROJECTILE":
			return Type.PROJECTILE
		"BITE":
			return Type.BITE
		"PUNCH":
			return Type.PUNCH
		"SOUND":
			return Type.SOUND
		_:
			push_error("Unknown move tag: " + value)
			return Type.CONTACT
