extends Player

var rice_index := 0
var rice := [Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT, Vector2.LEFT, Vector2.LEFT, Vector2.LEFT]

func _ready() -> void:
	super._ready()
	movement_finished.connect(func(): rice_index+= 1)

func _get_locked_input() -> Vector2:
	if rice_index == rice.size():
		rice_index = 0
	return rice[rice_index]

func _unhandled_input(event: InputEvent) -> void:
	pass
