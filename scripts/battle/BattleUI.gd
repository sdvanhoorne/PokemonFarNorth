extends Control
class_name BattleUI
 
@onready var message_box = $BottomUI/MessageContainer
@onready var moves_box = $BottomUI/MovesContainer
@onready var battle_options = $BottomUI/BattleOptionsUI
@onready var party_ui = $PartyUI

@onready var enemy_ui = $EnemyUI
@onready var enemy_pokemon_ui = enemy_ui.get_node("PokemonUI")
@onready var player_ui = $PlayerUI
@onready var player_pokemon_ui = player_ui.get_node("PokemonUI")
@onready var enemy_trainer_sprite = enemy_ui.get_node("EnemyTrainerSprite")

enum UIState { MESSAGE, OPTIONS, MOVES, PARTY, LOCKED }
var state: UIState = UIState.LOCKED
var prev_state: UIState = UIState.LOCKED

func _ready() -> void:
	DialogueManager.message_box = message_box
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_handle_cancel()
		get_viewport().set_input_as_handled()
		return
	
func _handle_cancel() -> void:
	match state:
		UIState.MOVES:
			set_state(UIState.OPTIONS)
		UIState.PARTY:
			set_state(UIState.OPTIONS)
		UIState.OPTIONS:
			pass
		_:
			pass

func set_state(new_state: UIState) -> void:
	if state == new_state:
		return

	prev_state = state
	state = new_state

	# Default: hide everything, then enable only what the state needs.
	_hide_all()

	match state:
		UIState.MESSAGE:
			message_box.visible = true
			# If MessageBox has a confirm button, focus it here.
			# message_box.grab_focus()

		UIState.OPTIONS:
			battle_options.visible = true
			# battle_options.grab_default_focus()

		UIState.MOVES:
			moves_box.visible = true
			# _refresh_moves()
			# moves_box.grab_default_focus()

		UIState.PARTY:
			party_ui.visible = true
			party_ui.load_party(PlayerInventory.PartyPokemon)
			# party_ui.grab_default_focus()

		UIState.LOCKED:
			message_box.visible = true
			# no inputs

func _show_pokemon_info(node: Control) -> void:
	node.get_node("")
	return

func _hide_all() -> void:
	message_box.visible = false
	moves_box.visible = false
	party_ui.visible = false
	battle_options.visible = false

func show_trainer_portrait(portrait: Texture2D) -> void:
	enemy_trainer_sprite.texture = portrait
	enemy_trainer_sprite.visible = true

func hide_trainer_portrait() -> void:
	enemy_trainer_sprite.visible = false

func show_player_back_portrait() -> void:
	# show the back sprite of the player
	return

func hide_player_back_portrait() -> void:
	# hide the back sprite of the player
	return

func load_player_pokemon(pokemon: Pokemon):
	_load_pokemon(player_pokemon_ui, pokemon)
	
func load_enemy_pokemon(pokemon: Pokemon):
	_load_pokemon(enemy_pokemon_ui, pokemon)

func _load_pokemon(node: Control, pokemon: Pokemon):
	node.visible = true
	var sprite_area = node.get_node("SpriteArea")
	sprite_area.visible = true
	var sprite = sprite_area.get_node("Sprite")
	sprite.texture = Paths.load_sprite(Paths.join(Paths.POKEMON_FRONT_SPRITES, pokemon.base_data.name))
	
	var info = node.get_node("Info")
	info.visible = true
	var nameLabel = info.get_node("Name")
	nameLabel.text = pokemon.base_data.name
	var levelLabel = info.get_node("Level")
	levelLabel.text = str(pokemon.level)
	var healthBar = info.get_node("Control/HealthBar")
	healthBar.max_value = pokemon.battle_stats.hp
	healthBar.value = pokemon.current_hp
	
	# load moves just for battle, maybe change later
	pokemon.moves.clear()
	for move_name in pokemon.move_names:
		pokemon.moves.append(MoveDatabase.get_move_by_name(move_name))
	
	# might not need to do this
	node.set_meta("pokemon", pokemon)

func _unload_pokemon(node: Control):
	var sprite_area = node.get_node("SpriteArea")
	sprite_area.visible = false
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func unload_player_pokemon():
	_unload_pokemon(player_pokemon_ui)

func unload_enemy_pokemon():
	_unload_pokemon(enemy_pokemon_ui)

func set_moves(move_names: Array) -> void:
	for i in range(4):
		var row := $BottomUI/MovesContainer/Moves/MovesFirstRow if i < 2 else $BottomUI/MovesContainer/Moves/MovesSecondRow
		var move_container := row.get_node("MoveContainer%d" % i) as PanelContainer
		var move_button := move_container.get_node("MoveButton%d" % i) as Button
		if i < move_names.size():
			var name = move_names[i]
			move_button.text = name
			move_button.disabled = false
			var move_type = MoveDatabase.get_move_by_name(name).type
			var type_color = TypeColors.color_for(move_type)
			var sb := move_container.get_theme_stylebox("panel").duplicate(true) as StyleBoxFlat
			sb.bg_color = type_color
			move_container.add_theme_stylebox_override("panel", sb)
		else:
			move_button.text = ""
			move_button.disabled = true
			var sb := move_container.get_theme_stylebox("panel").duplicate(true) as StyleBoxFlat
			sb.bg_color = Color(0.2, 0.2, 0.2, 1)
			move_container.add_theme_stylebox_override("panel", sb)
	
func update_health_bar(side: BattleDefinitions.BattleSide, current_hp: int, max_hp: int):
	var damagedPokemonContainer
	if(side == BattleDefinitions.BattleSide.ENEMY):
		damagedPokemonContainer = enemy_pokemon_ui
	else:
		damagedPokemonContainer = player_pokemon_ui
	var healthBar = damagedPokemonContainer.get_node("Info/Control/HealthBar")
	healthBar.value = current_hp
