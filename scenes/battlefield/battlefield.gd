extends Node2D

@onready var moveset_container: GridContainer = $Moveset

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
