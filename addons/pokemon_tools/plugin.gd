@tool
extends EditorPlugin

enum ResourceType {
	POKEMON,
	MOVE,
	ABILITY,
	ITEM
}

var creator_window: CreatorWindow
var current_type: ResourceType

func _enter_tree():
	add_tool_menu_item("New Pokémon", _create_pokemon)
	add_tool_menu_item("New Move", _create_move)
	add_tool_menu_item("New Ability", _create_ability)
	add_tool_menu_item("New Item", _create_item)

	var scene = load("res://addons/pokemon_tools/creator_window.tscn")
	creator_window = scene.instantiate()

	EditorInterface.get_base_control().add_child(creator_window)

	creator_window.confirmed.connect(_on_resource_confirmed)

func _exit_tree():
	remove_tool_menu_item("New Pokémon")
	remove_tool_menu_item("New Move")
	remove_tool_menu_item("New Ability")
	remove_tool_menu_item("New Item")

	if creator_window:
		creator_window.queue_free()

func _create_pokemon():
	current_type = ResourceType.POKEMON

	creator_window.name_edit.text = ""

	creator_window.show_generation_selector(true)
	creator_window.popup_centered()

func _create_move():
	current_type = ResourceType.MOVE
	creator_window.name_edit.text = ""
	creator_window.show_generation_selector(false)
	creator_window.popup_centered()

func _create_ability():
	current_type = ResourceType.ABILITY
	creator_window.name_edit.text = ""
	creator_window.show_generation_selector(false)
	creator_window.popup_centered()

func _create_item():
	current_type = ResourceType.ITEM
	creator_window.name_edit.text = ""
	creator_window.show_generation_selector(false)
	creator_window.popup_centered()

func _on_resource_confirmed():
	var resource_name: String = creator_window.get_resource_name()

	if resource_name.is_empty():
		push_warning("Debes ingresar un nombre.")
		return

	match current_type:
		ResourceType.POKEMON:
			_create_pokemon_resource(resource_name)

		ResourceType.MOVE:
			_create_move_resource(resource_name)

		ResourceType.ABILITY:
			_create_ability_resource(resource_name)

		ResourceType.ITEM:
			_create_item_resource(resource_name)

func _create_pokemon_resource(resource_name: String):
	var gen: String = creator_window.get_generation()

	var resource := PokemonDataStruct.new()

	var path := (
		"res://Data/Pokemon/%s/%s.tres"
		% [gen, resource_name]
	)

	ResourceSaver.save(resource, path)
	_open_resource(path)
	print("Creado:", path)

func _create_move_resource(resource_name: String):
	var resource := MoveData.new()

	var path := (
		"res://Data/Move/%s.tres"
		% resource_name
	)

	ResourceSaver.save(resource, path)
	_open_resource(path)
	print("Creado:", path)

func _create_ability_resource(resource_name: String):
	var resource := AbilityData.new()

	var path := (
		"res://Data/Ability/%s.tres"
		% resource_name
	)

	ResourceSaver.save(resource, path)
	_open_resource(path)
	print("Creado:", path)

func _create_item_resource(resource_name: String):
	var resource := ItemData.new()

	var path := (
		"res://Data/Items/%s.tres"
		% resource_name
	)

	ResourceSaver.save(resource, path)
	_open_resource(path)
	print("Creado:", path)

func _open_resource(path: String):
	var resource = load(path)

	EditorInterface.get_resource_filesystem().update_file(path)
	EditorInterface.edit_resource(resource)
