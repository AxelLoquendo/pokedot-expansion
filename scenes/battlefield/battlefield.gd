extends Node2D

signal animation_completed(result: Variant)

@onready var moveset_container: GridContainer = $UI/ColorRect/TextureRect/GridContainer
@onready var player_pokemon: Sprite2D = $Pikachu
@onready var foe_pokemon: Sprite2D = $Pidgey
@onready var player_label: Label = $UI/PlayerPanel/Label
@onready var foe_label: Label = $UI/FoePanel/Label
@onready var player_hp_bar: TextureProgressBar = $UI/PlayerPanel/TextureProgressBar
@onready var foe_hp_bar: TextureProgressBar = $UI/FoePanel/TextureProgressBar


func _ready() -> void:
	var pbattle := PBattle.new()
	add_child(pbattle)
	
	$UI/ColorRect/TextureRect/GridContainer/TextureButton.connect("pressed", pbattle.write.bind("move 1"))
	$UI/ColorRect/TextureRect/GridContainer/TextureButton2.connect("pressed", pbattle.write.bind("move 2"))
	$UI/ColorRect/TextureRect/GridContainer/TextureButton3.connect("pressed", pbattle.write.bind("move 3"))
	$UI/ColorRect/TextureRect/GridContainer/TextureButton4.connect("pressed", pbattle.write.bind("move 4"))
	
	$UI/ColorRect/TextureRect/GridContainer/TextureButton.grab_focus()


func display_moveset(moveset: Array) -> void:
	for i in range(moveset.size()):
		moveset_container.get_child(i).get_child(0).text = moveset[i]
	show_options()


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


func message(msg: String) -> void:
	$UI/Message/RichTextLabel.visible_ratio = 0
	$UI/Message/RichTextLabel.text = msg

	$UI/Message.show()
	var tw = create_tween()
	const SECONDS_PER_CHAR: float = 1.0 / 15
	tw.tween_property($UI/Message/RichTextLabel, "visible_ratio", 1, msg.length() * SECONDS_PER_CHAR)
	await tw.finished
	await get_tree().create_timer(1).timeout
	$UI/Message.hide()


func splash(pokemon: String, ability: String) -> void:
	#$AbilityBar/Pokemon.text = pokemon
	$UI/AbilityBar/Label.text = ability

	var tw = create_tween()
	tw.tween_property($UI/AbilityBar, "position:x", 260, 0.8)
	tw.tween_property($UI/AbilityBar, "position:x", 260, 1)
	tw.tween_property($UI/AbilityBar, "position:x", 520, 0.4)
	await tw.finished


func animate(func_str: String, argv: Array) -> void:
	await callv(func_str, argv)
	emit_signal("animation_completed", null)


func switch(ident: String, max_hp: int, hp: int) -> void:
	var sprite2d = player_pokemon if ident.begins_with("p1a") else foe_pokemon
	var label = player_label if ident.begins_with("p1a") else foe_label
	var hp_bar = player_hp_bar if ident.begins_with("p1a") else foe_hp_bar

	# Incluir el manejo de pokemon con variantes

	var pokemon = ident.substr(5).replace("-", "").replace(" ", "")
	var pokemon_id = pokemon.to_lower()

	player_hp_bar.set_max(max_hp)
	player_hp_bar.set_value(hp)
	label.text = pokemon
	sprite2d.texture = load("res://graphics/pokemon/front/%s.png" % pokemon_id)
