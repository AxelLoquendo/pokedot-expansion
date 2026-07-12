extends Node

@onready var p_server: PServer = $PServer

func _ready() -> void:
	var species = p_server.get_species("pikachu")
