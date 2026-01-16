extends Control

class_name BattleUI
 
@onready var message_box = $MessageBox
@onready var moves_box = $MovesBox
@onready var party_ui = $PartyUI
@onready var battle_options = $BattleOptionsUI
@onready var enemy_pokemon_ui = $EnemyPokemonUI/EnemyPokemon
@onready var player_pokemon_ui = $PlayerPokemonUI/PlayerPokemon

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

#func _handle_accept() -> void:
#	match state:
#		UIState.MESSAGE:
#			emit_signal("advance_message")
#		_:
#			# In OPTIONS/MOVES/PARTY, accept is usually handled by focused buttons
#			pass


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

func _hide_all() -> void:
	message_box.visible = false
	moves_box.visible = false
	party_ui.visible = false
	battle_options.visible = false

func load_player_pokemon(pokemon: Pokemon):
	_load_pokemon(player_pokemon_ui, pokemon)
	
func load_enemy_pokemon(pokemon: Pokemon):
	_load_pokemon(enemy_pokemon_ui, pokemon)

func _load_pokemon(node: Node2D, pokemon: Pokemon):
	var sprite = node.get_node("SpriteArea").get_node("Sprite")
	sprite.texture = load("res://assets/pokemon/" + pokemon.base_data.name + ".png")	
	var nameLabel = node.get_node("Info/Name")
	nameLabel.text = pokemon.base_data.name
	var levelLabel = node.get_node("Info/Level")
	levelLabel.text = str(pokemon.level)
	var healthBar = node.get_node("Info/Control/HealthBar")
	healthBar.max_value = pokemon.battle_stats.hp
	healthBar.value = pokemon.battle_stats.hp
	
	# load moves just for battle, maybe change later
	pokemon.moves.clear()
	for move_name in pokemon.move_names:
		pokemon.moves.append(MoveDatabase.get_move_by_name(move_name))
	
	# might not need to do this
	node.set_meta("pokemon", pokemon)

func _unload_pokemon(node: Node2D):
	var sprite_area = node.get_node("SpriteArea")
	sprite_area.visible = false
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func unload_player_pokemon():
	_unload_pokemon(player_pokemon_ui)

func unload_enemy_pokemon():
	_unload_pokemon(enemy_pokemon_ui)
	
# sets button text for active pokemon moves
func set_moves(move_names: Array) -> void:
	var button_index = 0
	for move_name in move_names:
		_set_move(button_index, move_name)
		button_index += 1
	
func _set_move(i: int, move_name: String):
	var move_button = moves_box.get_node("PokemonMoves").get_node("Move" + str(i))	
	move_button.text = move_name
	
func update_health_bar(defending_pokemon: Pokemon, isPlayerAttacking: bool):
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = enemy_pokemon_ui
	else:
		damagedPokemonContainer = player_pokemon_ui
	var healthBar = damagedPokemonContainer.get_node("Info/Control/HealthBar")
	healthBar.value = defending_pokemon.current_hp
