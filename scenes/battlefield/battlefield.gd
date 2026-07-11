extends Node2D

@onready var moveset_container: GridContainer = $Moveset
@onready var player_pokemon: Sprite2D = $PlayerPokemon
@onready var foe_pokemon: Sprite2D = $FoePokemon

@onready var player_label: Label = $PlayerPanel/Label
@onready var foe_label: Label = $FoePanel/Label

@onready var player_hp_bar: ProgressBar = $PlayerPanel/HPBar
@onready var foe_hp_bar: ProgressBar = $FoePanel/HPBar


func _ready() -> void:
	var sd := Showdown.new()
	add_child(sd)

func display_moveset(moveset: Array) -> void:
	for i in range(moveset.size()):
		var btn: Button = moveset_container.get_child(i)
		btn.text = moveset[i]
	moveset_container.show()

func show_options() -> void:
	moveset_container.show()

func hide_options() -> void:
	moveset_container.hide()
	
func take_damage(position: String, damage: int) -> void:
	var tw = create_tween()
	var hp_bar = player_hp_bar if position == "p1a" else foe_hp_bar
	const FACTOR_MILISECONDS_PER_POINTS = 0.006
	var duration = abs(hp_bar.value - damage) * FACTOR_MILISECONDS_PER_POINTS
	tw.tween_property(hp_bar, "value", damage, duration).set_ease(Tween.EASE_OUT)
	
	await tw.finished
