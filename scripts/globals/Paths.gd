extends Node

# --- Root folders ---
const ASSETS_ROOT := "res://assets"
const POKEMON_ROOT := ASSETS_ROOT + "/pokemon"
const UI_ROOT := ASSETS_ROOT + "/ui"
const AUDIO_ROOT := ASSETS_ROOT + "/audio"

# --- Pokemon specific subfolders ---
const POKEMON_FRONT_SPRITES := POKEMON_ROOT
#const POKEMON_BACK_SPRITES  := POKEMON_ROOT + "/back"
#const POKEMON_ICONS         := POKEMON_ROOT + "/icons"

static func join(a: String, b: String) -> String:
	if a.ends_with("/"):
		a = a.trim_suffix("/")
	if b.begins_with("/"):
		b = b.trim_prefix("/")
	return a + "/" + b

# --- Helpers: load resources safely ---
static func load_sprite(path: String) -> Texture2D:
	path = path + ".png"
	var res := load(path)
	if res == null:
		push_error("Missing Texture2D at: %s" % path)
		return null
	if res is Texture2D:
		return res
	push_error("Resource at %s is not a Texture2D (got %s)" % [path, typeof(res)])
	return null
