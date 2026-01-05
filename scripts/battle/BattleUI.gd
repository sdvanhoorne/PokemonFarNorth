extends Control

class_name BattleUI
 
@onready var messageBox = $MessageBox
@onready var PartyUI = $PartyUI/Party
@onready var BattleOptions = $BattleOptions
@onready var EnemyPokemonContainer = $EnemyPokemonUI/EnemyPokemon
@onready var PlayerPokemonContainer = $PlayerPokemonUI/PlayerPokemon

func load_player_pokemon(pokemon: Pokemon):
	load_pokemon(PlayerPokemonContainer, pokemon)
	
func load_enemy_pokemon(pokemon: Pokemon):
	load_pokemon(EnemyPokemonContainer, pokemon)

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
	unload_pokemon(PlayerPokemonContainer)

func unload_enemy_pokemon():
	unload_pokemon(EnemyPokemonContainer)
	
func show_moves():
	messageBox.get_node("Message").visible = false
	messageBox.get_node("PokemonMoves").visible = true
	set_move(0)
	set_move(1)
	set_move(2)
	set_move(3)
	
func set_move(i: int):
	# might want to set an active pokemon 
	var moves = PlayerInventory.PartyPokemon[0].moves
	if i >= moves.size():
		return
	var move_button = messageBox.get_node("PokemonMoves").get_node("Move" + str(i))	
	var pokemon_move = moves[i]["name"]
	if(pokemon_move == null):
		move_button.text = ""
	move_button.text = pokemon_move
	
func update_health_bar(damage: int, defending_pokemon: Pokemon, isPlayerAttacking: bool):
	var damagedPokemonContainer
	if(isPlayerAttacking):
		damagedPokemonContainer = EnemyPokemonContainer
	else:
		damagedPokemonContainer = PlayerPokemonContainer
	var healthBar = damagedPokemonContainer.get_node("Info/HealthBar")
	healthBar.value = defending_pokemon.current_hp
	
func show_dialogue():
	messageBox.get_node("PokemonMoves").visible = false
	messageBox.get_node("Message").visible = true
		
func print_dialogue(message: PackedStringArray):
	show_dialogue()
	DialogueManager.start_dialogue(message)
	await get_tree().process_frame
	await Helpers.wait(2)
	
func show_battle_options():
	BattleOptions.visible = true
	
func hide_battle_options():
	BattleOptions.visible = false
	
func hide_moves():
	messageBox.get_node("PokemonMoves").visible = false

func _on_switch_pressed() -> void:
	show_party()
	
func show_party():
	PartyUI.visible = true
	
func hide_party():
	PartyUI.visible = false
