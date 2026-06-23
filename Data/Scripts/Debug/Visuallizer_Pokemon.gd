@tool
extends Control

var icon_timer := 0.0
var current_icon_frame := 0
var shiny_mode := false
@export var pokemon_data: PokemonDataStruct:
	set(value):
		pokemon_data = value
		if is_inside_tree():
			update_visualizer()

@export_file("*.tres")
var pokemon_path: String:
	set(value):
		pokemon_path = value

		if pokemon_path != "":
			pokemon_data = load(pokemon_path)

		if is_inside_tree():
			update_visualizer()

func _ready():
	set_process(true)
	update_visualizer()

func _process(delta):
	if pokemon_data == null:
		return

	icon_timer += delta

	if icon_timer >= 0.25:
		icon_timer = 0.0

		current_icon_frame = 1 - current_icon_frame

		$Icon.frame = current_icon_frame

func update_visualizer():
	if pokemon_data == null:
		return

	if shiny_mode:
		$FrontSprite.texture = pokemon_data.front_sprite_shiny
		$BackSprite.texture = pokemon_data.back_sprite_shiny
	else:
		$FrontSprite.texture = pokemon_data.front_sprite
		$BackSprite.texture = pokemon_data.back_sprite

	$Icon.texture = pokemon_data.icon_sprite

	$Icon.hframes = 1
	$Icon.vframes = 2
	$Icon.frame = 0

	$FrontSprite.position = pokemon_data.front_sprite_offset
	$BackSprite.position = pokemon_data.back_sprite_offset

	$Species_Name.text = pokemon_data.species_name

	$Species_ID.text = (
		"N°%04d - %s"
		% [
			pokemon_data.national_dex_number,
			Species.SpeciesId.keys()[pokemon_data.species_id]
		]
	)
	var data_hab_1 = DataBaseGlobal.abilities.get(pokemon_data.ability_1)
	var data_hab_2 = DataBaseGlobal.abilities.get(pokemon_data.ability_2)
	if data_hab_1:
		$Ability1.text = data_hab_1.ability_name
	else:
		$Ability1.text = "----"
	if data_hab_2:
		$Ability2.text = data_hab_2.ability_name
	else:
		$Ability2.text = "----"

func _input(event):
	if event.is_action_pressed("ui_accept"):
		shiny_mode = !shiny_mode
		update_visualizer()
