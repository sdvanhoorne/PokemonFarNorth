extends Control

class_name BattleUI
 
@onready var message_box = $MessageBox
@onready var moves_box = $MovesBox
@onready var party_ui = $PartyUI
@onready var battle_options = $BattleOptionsUI
@onready var enemy_pokemon_ui = $EnemyPokemonUI/EnemyPokemon
@onready var player_pokemon_ui = $PlayerPokemonUI/PlayerPokemon

func _ready() -> void:
	DialogueManager.message_box = message_box

func load_player_pokemon(pokemon: Pokemon):
	load_pokemon(player_pokemon_ui, pokemon)
	
func load_enemy_pokemon(pokemon: Pokemon):
	load_pokemon(enemy_pokemon_ui, pokemon)

func load_pokemon(node: Node2D, pokemon: Pokemon):
	var sprite = node.get_node("SpriteArea").get_node("Sprite")
	sprite.texture = load("res://assets/pokemon/ai/" + pokemon.base_data.name + ".png")	
	var nameLabel = node.get_node("Info/Name")
	nameLabel.text = pokemon.base_data.name
	var levelLabel = node.get_node("Info/Level")
	levelLabel.text = str(pokemon.level)
	var healthBar = node.get_node("Info/HealthBar")
	healthBar.max_value = pokemon.battle_stats.hp
	healthBar.value = pokemon.battle_stats.hp
	
	for move_name in pokemon.move_names:
		pokemon.moves.append(MoveDatabase.get_move_by_name(move_name))
		
	node.set_meta("pokemon", pokemon)

func unload_pokemon(node: Node2D):
	var infoArea = node.get_node("SpriteArea")
	var sprite = infoArea.get_node("Sprite")
	sprite.texture = null
	# show fainting animation?
	var info = node.get_node("Info")
	info.visible = false
	
func unload_player_pokemon():
	unload_pokemon(player_pokemon_ui)

func unload_enemy_pokemon():
	unload_pokemon(enemy_pokemon_ui)
	
func show_moves():
	message_box.visible = false
	moves_box.visible = true
	set_move(0)
	set_move(1)
	set_move(2)
	set_move(3)
	
func set_move(i: int):
	# might want to set an active pokemon 
	var moves = PlayerInventory.PartyPokemon[0].moves
	if i >= moves.size():
		return
	var move_button = moves_box.get_node("PokemonMoves").get_node("Move" + str(i))	
	var pokemon_move = moves[i]["name"]
	if(pokemon_move == null):
		move_button.text = ""
	move_button.text = pokemon_move
	
func update_health_bar(defending_pokemon: Pokemon, isPlayerAttacking: bool):
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = enemy_pokemon_ui
	else:
		damagedPokemonContainer = player_pokemon_ui
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defending_pokemon.current_hp
	
func show_dialogue():
	moves_box.visible = false
	message_box.visible = true
	
func show_battle_options():
	battle_options.visible = true
	
func hide_battle_options():
	battle_options.visible = false
	
func hide_moves():
	moves_box.visible = false

func _on_switch_pressed() -> void:
	hide_battle_options()
	hide_moves()
	show_party()
	
func show_party():
	party_ui.visible = true
	party_ui.load_party(PlayerInventory.PartyPokemon)
	
func hide_party():
	party_ui.visible = false
