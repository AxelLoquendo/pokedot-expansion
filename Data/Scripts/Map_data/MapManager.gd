extends Node

class_name MapManager

@export var initial_map: PackedScene
@export var tile_size: int = 16
@export var player: CharacterBody2D
@export var initial_player_tile: Vector2i = Vector2i(5, 5)

@onready var current_map_container: Node2D = $CurrentMapContainer
@onready var neighbor_map_container: Node2D = $NeighborMapContainer

var current_map: GameMap

func tile_a_posicion(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos * tile_size) + Vector2(8, 16)

func _ready():
	cargar_mapa_inicial()

	if player != null:
		player.position = tile_a_posicion(initial_player_tile)
		player.paso_terminado.connect(_on_player_paso_terminado)

func _on_player_paso_terminado():
	revisar_salida_del_mapa()

func cargar_mapa_inicial():
	if initial_map == null:
		return
		
	current_map = initial_map.instantiate()
	current_map_container.add_child(current_map)
	cargar_vecinos()

func revisar_salida_del_mapa():
	if current_map == null:
		return
	
	if current_map.attributes == null:
		push_warning("El mapa actual no tiene MapAttributes asignado.")
		return
	
	var _tile_pos := posicion_a_tile(player.position)
	
	var size := current_map.attributes.map_size
	
	if _tile_pos.x < 0:
		cambiar_mapa("west", _tile_pos)
	elif _tile_pos.x >= size.x:
		cambiar_mapa("east", _tile_pos)
	elif _tile_pos.y < 0:
		cambiar_mapa("north", _tile_pos)
	elif _tile_pos.y >= size.y:
		cambiar_mapa("south", _tile_pos)

func cambiar_mapa(_direction: String, _old_tile_pos: Vector2i):
	var connection := obtener_conexion(_direction)
	
	if connection == null:
		return
	
	if connection.map_scene_path.is_empty():
		return

	var next_scene := load(connection.map_scene_path) as PackedScene

	if next_scene == null:
		return
	
	player.cancelar_encadenado()
	
	current_map.queue_free()
	limpiar_vecinos()

	current_map = next_scene.instantiate()
	current_map_container.add_child(current_map)

	if current_map.attributes == null:
		push_warning("El nuevo mapa no tiene MapAttributes asignado.")
		return

	var new_tile_pos := calcular_posicion_entrada(
		_direction,
		_old_tile_pos,
		current_map.attributes.map_size,
		connection.offset
	)

	player.position = tile_a_posicion(new_tile_pos)
	cargar_vecinos()
	
func obtener_conexion(_direction: String) -> MapConnection:
	match _direction:
		"north":
			return current_map.attributes.north_map
		"east":
			return current_map.attributes.east_map
		"south":
			return current_map.attributes.south_map
		"west":
			return current_map.attributes.west_map

	return null
	
func calcular_posicion_entrada(direction: String,old_tile_pos: Vector2i,new_map_size: Vector2i,offset: int) -> Vector2i:
	match direction:
		"east":
			return Vector2i(0, old_tile_pos.y + offset)
		"west":
			return Vector2i(new_map_size.x - 1, old_tile_pos.y + offset)
		"north":
			return Vector2i(old_tile_pos.x + offset, new_map_size.y - 1)
		"south":
			return Vector2i(old_tile_pos.x + offset, 0)

	return old_tile_pos

func limpiar_vecinos():
	for child in neighbor_map_container.get_children():
		child.queue_free()

func cargar_vecinos():
	limpiar_vecinos()

	if current_map == null:
		return

	cargar_vecino("north")
	cargar_vecino("east")
	cargar_vecino("south")
	cargar_vecino("west")
	
func cargar_vecino(direction: String):
	var connection := obtener_conexion(direction)

	if connection == null:
		return

	if connection.map_scene_path.is_empty():
		return

	var scene := load(connection.map_scene_path) as PackedScene

	if scene == null:
		return

	var neighbor := scene.instantiate() as GameMap

	if neighbor == null:
		return

	if neighbor.attributes == null:
		push_warning("El mapa vecino no tiene MapAttributes asignado.")
		neighbor.queue_free()
		return

	neighbor_map_container.add_child(neighbor)

	var current_size_px := Vector2(current_map.attributes.map_size * tile_size)
	var neighbor_size_px := Vector2(neighbor.attributes.map_size * tile_size)
	var offset_px := float(connection.offset * tile_size)

	match direction:
		"east":
			neighbor.position = Vector2(current_size_px.x, -offset_px)
		"west":
			neighbor.position = Vector2(-neighbor_size_px.x, -offset_px)
		"north":
			neighbor.position = Vector2(-offset_px, -neighbor_size_px.y)
		"south":
			neighbor.position = Vector2(-offset_px, current_size_px.y)

func puede_caminar(player_pos: Vector2, dir: Vector2) -> bool:
	var collision := current_map.behaviours.get_node("Collision") as TileMapLayer
	var current_tile := collision.local_to_map(player_pos)
	var target_tile := current_tile + Vector2i(dir)

	#print("Pos:", player_pos)
	#print("Current:", current_tile)
	#print("Target:", target_tile)

	return not current_map.tile_bloqueado(target_tile)

func posicion_a_tile(pos: Vector2) -> Vector2i:
	var adjusted_pos := pos - Vector2(8, 16)

	return Vector2i(
		floori(adjusted_pos.x / tile_size),
		floori(adjusted_pos.y / tile_size)
	)
