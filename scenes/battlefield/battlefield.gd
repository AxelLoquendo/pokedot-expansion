extends Node2D

func _ready() -> void:
	var sim := SimBridge.new()
	var source := FileAccess.open("res://scenes/battlefield/sim.js", FileAccess.READ).get_as_text()
	sim.evaluate(source)
