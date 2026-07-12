extends Node
class_name PlayerManagerNode

var viene_de_continuar: bool = false
var data: PlayerData = PlayerData.new()
var ruta_escena_anterior: String = ""

func new_game(player_name: String, ranura_destino: int = -1):
	data = PlayerData.new()
	data.player_name = player_name
	data.money = 3000
	data.badges = []
	data.flags = {}
	data.items = {"POTION": 5, "POKEBALL": 10}
	data.party = []
	
	# 🌟 CORREGIDO: En vez de -1 a fuego, le ponemos la ranura elegida en el menú
	data.ranura_guardada = ranura_destino
	print("⚙️ PlayerManager: Inicializando nueva partida en la ranura: ", ranura_destino)
	
	# 👇 Actualizamos ambas propiedades
	data.current_map_scene = "res://data_core/maps/prado_natal/prado_natal.tscn"
	data.current_map_section = MapSections.SectionID.MAPSEC_PRADO_NATAL

	data.grid_position = Vector2i(7, 10)
	data.direction = Vector2.DOWN
	data.play_time = 0.0
	data.ranura_guardada = ranura_destino

func add_pokemon(pokemon) -> bool:
	if data.party.size() < PlayerData.MAX_PARTY:
		data.party.append(pokemon)
		return true
	return false


func remove_pokemon(index: int):
	if index >= 0 and index < data.party.size():
		data.party.remove_at(index)


func add_item(item_id, amount: int = 1):
	var clave = str(item_id)
	data.items[clave] = data.items.get(clave, 0) + amount


func remove_item(item_id, amount: int = 1):
	var clave = str(item_id)
	var actual = data.items.get(clave, 0)
	if actual - amount <= 0:
		data.items.erase(clave)
	else:
		data.items[clave] = actual - amount
