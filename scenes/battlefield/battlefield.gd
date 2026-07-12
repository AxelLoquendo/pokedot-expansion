extends Node2D

signal animation_completed(result: Variant)

@onready var moveset_container: GridContainer = $OverlayFight/Moveset
@onready var player_pokemon: Sprite2D = $PlayerPokemon
@onready var foe_pokemon: Sprite2D = $FoePokemon

@onready var player_label: Label = $PlayerPanel/Label
@onready var foe_label: Label = $FoePanel/Label

@onready var player_hp_bar: ProgressBar = $PlayerPanel/HPBar
@onready var foe_hp_bar: ProgressBar = $FoePanel/HPBar


func _ready() -> void:
	var pbattle := PBattle.new()
	add_child(pbattle)

func display_moveset(moveset: Array) -> void:
	for i in range(moveset.size()):
		var btn: Button = moveset_container.get_child(i)
		btn.text = moveset[i]
	show_options()

func show_options() -> void:
	$OverlayFight.show()

func hide_options() -> void:
	$OverlayFight.hide()
	
func take_damage(position: String, damage: int) -> void:
	var tw = create_tween()
	var hp_bar = player_hp_bar if position == "p1a" else foe_hp_bar
	const FACTOR_MILISECONDS_PER_POINTS = 0.006
	var duration = abs(hp_bar.value - damage) * FACTOR_MILISECONDS_PER_POINTS
	tw.tween_property(hp_bar, "value", damage, duration).set_ease(Tween.EASE_OUT)
	
	await tw.finished
	
func message(msg: String) -> void:
	$OverlayMessage/RichTextLabel.visible_ratio = 0
	$OverlayMessage/RichTextLabel.text = msg
	
	$OverlayMessage.show()
	var tw = create_tween()
	const SECONDS_PER_CHAR: float = 1.0/15
	tw.tween_property($OverlayMessage/RichTextLabel, "visible_ratio", 1, msg.length() * SECONDS_PER_CHAR)
	await tw.finished
	await get_tree().create_timer(1).timeout
	$OverlayMessage.hide()

func splash(pokemon: String, ability: String) -> void:
	$AbilityBar/Pokemon.text = pokemon
	$AbilityBar/Ability.text = ability
	
	var tw = create_tween()
	tw.tween_property($AbilityBar, "position:x", 216, 1)
	tw.tween_property($AbilityBar, "position:x", 216, 1)
	tw.tween_property($AbilityBar, "position:x", 296, 0.6)
	await tw.finished
	
func animate(func_str: String, argv: Array) -> void:
	await callv(func_str, argv)
	emit_signal("animation_completed", null)
