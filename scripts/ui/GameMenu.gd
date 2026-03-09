extends Node2D

enum menu_state { NONE, MAIN, POKEDEX, PARTY, BAG, SAVE, OPTIONS }
var current_menu: menu_state

@onready var pokedex_menu: CanvasLayer = $PokedexMenu
@onready var party_menu: CanvasLayer = $PartyMenu
@onready var main_menu: CanvasLayer = $MainMenu

func _ready() -> void:
	current_menu = menu_state.NONE
	main_menu.visible = false
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if current_menu == menu_state.NONE:
			_open_main_menu()
		elif current_menu == menu_state.MAIN:
			_close_main_menu()
		elif current_menu == menu_state.POKEDEX:
			_close_pokedex_menu()
		elif current_menu == menu_state.PARTY:
			_close_party_menu()
		
		get_viewport().set_input_as_handled()

func _open_main_menu() -> void:
	GameState.lock_gameplay_input()
	current_menu = menu_state.MAIN
	main_menu.visible = true
	
func _close_main_menu() -> void:
	main_menu.visible = false
	current_menu = menu_state.NONE
	GameState.unlock_gameplay_input()

func _on_pokedex_pressed() -> void:
	main_menu.visible = false
	pokedex_menu.visible = true
	pokedex_menu.load_pokemon_list()
	current_menu = menu_state.POKEDEX
	
func _on_party_pressed() -> void:
	main_menu.visible = false
	party_menu.visible = true
	party_menu.load_party(PlayerInventory.PartyPokemon)
	current_menu = menu_state.PARTY
	
func _close_pokedex_menu() -> void:
	pokedex_menu.visible = false
	main_menu.visible = true
	current_menu = menu_state.MAIN
	
func _close_party_menu() -> void:
	party_menu.visible = false
	main_menu.visible = true
	current_menu = menu_state.MAIN
