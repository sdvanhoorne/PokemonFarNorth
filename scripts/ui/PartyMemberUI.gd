extends PanelContainer
class_name PartyMemberUI

@onready var sprite_rect: TextureRect = %Sprite2D
@onready var name_label: Label = %Name
@onready var level_label: Label = %Level
@onready var hp_label: Label = %Health
@onready var hp_bar: TextureProgressBar = %HealthBar

func set_pokemon(pokemon: Pokemon) -> void:
	name_label.text = str(pokemon.base_data.name)
	level_label.text = "Lv. %d" % int(pokemon.level)

	var hp := int(pokemon.current_hp)
	var max_hp = int(pokemon.stats.hp)

	hp_label.text = "%d/%d" % [hp, max_hp]

	# Bar fill (fixed bar size; only value changes)
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = clamp(hp, 0, max_hp)

	# we need to keep a global references file to maintain paths
	var sprite_path = Paths.join(Paths.POKEMON_FRONT_SPRITES, pokemon.base_data.name)
	var sprite = Paths.load_sprite(sprite_path)
	sprite_rect.texture = sprite

	var pct := float(hp) / float(max_hp)
	if pct <= 0.2:
		hp_bar.tint_progress = Color(1.0, 0.2, 0.2) # red
	elif pct <= 0.5:
		hp_bar.tint_progress = Color(1.0, 0.9, 0.2) # yellow
	else:
		hp_bar.tint_progress = Color(0.2, 1.0, 0.3) # green
