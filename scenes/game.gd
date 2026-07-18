extends Node

#@onready var p_server: PServer = $PServer
@export var battle_scene: Node


func _ready() -> void:
	pass
	#p_battle = PBattle.new()
	#battle_scene.add_child(p_battle)
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


func _input(event: InputEvent) -> void:
	if event.is_pressed() and event.as_text() == "B":
		battle_scene.pbattlepeer = PBattlePeer.new()
		battle_scene.pbattlepeer.start(battle_scene.player_name, "Arcanine||Leftovers|Intimidate|Flareblitz,Extremespeed,Wildcharge,Morningsun|Impish|252,0,252,0,4,0||||||||")
		battle_scene.connect("battle_finished", _battle_finished)
		battle_scene.present()

		$Overworld/Player.process_mode = Node.PROCESS_MODE_DISABLED

		get_viewport().set_input_as_handled()

	if event.is_pressed() and event.as_text() == "F":
		battle_scene.dispose()
		$Overworld/Player.process_mode = Node.PROCESS_MODE_INHERIT

		get_viewport().set_input_as_handled()


func _battle_finished(result: String) -> void:
	await get_tree().create_timer(1.0).timeout
	battle_scene.dispose()

	$Overworld/Player.process_mode = Node.PROCESS_MODE_INHERIT


func _on_player_interact(message: String) -> void:
	$GUI/SpeechMenu.speech(message)
