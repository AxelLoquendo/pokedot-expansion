extends Node

@onready var p_server: PServer = $PServer
@onready var pokemon: Sprite2D = $Pokemon


func _ready() -> void:
	pass
	# - No de incluye las versiones femeninas
	# - Las variantes Gmax utiliza el sufijo _gmax en lugas de algun numero
	# - Es muy muy probable que existan sprites de pokemon essentials
	# que tenga sufijo que no concuerde con su forme order
	#var species = JSON.parse_string(p_server.get_species("raichumegax"))
	#
	#var species_id: String = species.get("baseSpecies", species["id"])
	#var species_name: String = species["name"]
	#var forme_order: Array = species["formeOrder"]
	#
	#var i := forme_order.find(species_name)
	#var n = "" if i == 0 else "_" + str(i)
	#
	#var path := "res://graphics/pokemon/front/%s.png" % [species_id.to_upper() + n]
	#var sprite: Texture2D = load(path)
	#pokemon.texture = sprite
