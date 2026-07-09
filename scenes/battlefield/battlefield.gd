extends Node2D

@onready var moveset_container: GridContainer = $Moveset
@onready var player_pokemon: Sprite2D = $PlayerPokemon
@onready var foe_pokemon: Sprite2D = $FoePokemon

@onready var player_label: Label = $PlayerPanel/Label
@onready var foe_label: Label = $FoePanel/Label

func _ready() -> void:
	var sd := Showdown.new()
	add_child(sd)

func display_moveset(moveset: Array) -> void:
	for i in range(moveset.size()):
		var btn: Button = moveset_container.get_child(i)
		btn.text = moveset[i]
	moveset_container.show()

func hide_options() -> void:
	moveset_container.hide()
