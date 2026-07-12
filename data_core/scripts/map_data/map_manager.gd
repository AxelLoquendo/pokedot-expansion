extends Node
## Clase administradora global del entorno.
## Controla la carga y descarga de mapas, la costura de mapas vecinos en tiempo real,
## las posiciones relativas del jugador y el puente lógico para colisiones y eventos.
class_name MapManager

@export var map_data: MapAttributes
@export var initial_map: PackedScene # Escena del mapa donde iniciará la partida
@export var tile_size: int = 16 # Tamaño en píxeles de las baldosas
@export var player: CharacterBody2D # Referencia al nodo del jugador
@export var initial_player_tile: Vector2i = Vector2i(5, 5) # Coordenada inicial de spawn

@onready var current_map_container: Node2D = $CurrentMapContainer # Contenedor del mapa activo
@onready var neighbor_map_container: Node2D = $NeighborMapContainer # Contenedor de mapas adyacentes

var current_map: GameMap # Instancia del mapa que el jugador está pisando actualmente

## Convierte una coordenada de la cuadrícula a una posición en píxeles del mundo 2D.
## Añade un desfase de (8, 16) para centrar el pivote del sprite del jugador en el tile.
func tile_a_posicion(tile_pos: Vector2i) -> Vector2:
	return Vector2(tile_pos * tile_size) + Vector2(8, 16)

func _ready():
	var cargar_desde_guardado: bool = false

	# 🌟 CORREGIDO: Evaluamos la bandera global en lugar de si la ruta está vacía
	if PlayerManager and PlayerManager.viene_de_continuar:
		# Cargar desde datos guardados reales
		var mapa_ruta = PlayerManager.data.current_map_scene
		initial_map = load(mapa_ruta)
		cargar_desde_guardado = true
	else:
		# Si es partida nueva, mantenemos la configuración por defecto
		print("🌱 Iniciando entorno desde Nueva Partida")

	# 🚀 EJECUTAMOS SOLO UNA OPCIÓN
	if cargar_desde_guardado:
		cargar_mapa_desde_guardado()
	else:
		cargar_mapa_inicial()

	if player:
		player.direccion = PlayerManager.data.direction
		player.paso_terminado.connect(_on_player_paso_terminado)

## Se ejecuta automáticamente cada vez que el jugador termina de dar un paso completo.
func _on_player_paso_terminado():
	revisar_salida_del_mapa()
	if PlayerManager and current_map and current_map.attributes:
		var tile_pos = posicion_a_tile(player.position)
		PlayerManager.data.grid_position = tile_pos
		PlayerManager.data.direction = player.direccion
		PlayerManager.data.current_map_scene = current_map.scene_file_path
		PlayerManager.data.current_map_section = current_map.attributes.map_section_id

## Instancia y añade el mapa base al contenedor principal al arrancar el juego.
func cargar_mapa_inicial():
	if not initial_map:
		return
		
	current_map = initial_map.instantiate()
	current_map_container.add_child(current_map)
	cargar_vecinos()

	if current_map and current_map.attributes:
		MusicManager.reproducir(current_map.attributes.music_path, current_map.attributes.silence_end)
		TimeManager.set_indoors(current_map.attributes.is_indoor)
		PlayerManager.data.current_map_section = current_map.attributes.map_section_id
	else:
		push_warning("⚠️ Mapa inicial sin MapAttributes asignado")
		if PlayerManager:
			PlayerManager.data.current_map_section = MapSections.SectionID.MAPSEC_NONE

	# 🎯 Aplicamos posición guardada SIEMPRE que sea válida
	if not player:
		return

	if PlayerManager and PlayerManager.data.grid_position != Vector2i(0, 0):
		initial_player_tile = PlayerManager.data.grid_position
		print("✅ Aplicando posición guardada en mapa: ", initial_player_tile)
	else:
		print("ℹ️ Usando posición inicial: ", initial_player_tile)

	player.position = tile_a_posicion(initial_player_tile)
	player.direccion = PlayerManager.data.direction

## Comprueba si el jugador ha cruzado los límites lógicos del mapa actual (Norte, Sur, Este, Oeste).
func revisar_salida_del_mapa():
	if not current_map or not current_map.attributes:
		push_warning("Mapa sin atributos asignados")
		return
	
	var _tile_pos = posicion_a_tile(player.position)
	var size = current_map.attributes.map_size

	if _tile_pos.x < 0:
		cambiar_mapa("west", _tile_pos)
	elif _tile_pos.x >= size.x:
		cambiar_mapa("east", _tile_pos)
	elif _tile_pos.y < 0:
		cambiar_mapa("north", _tile_pos)
	elif _tile_pos.y >= size.y:
		cambiar_mapa("south", _tile_pos)

## Descarga el mapa anterior, limpia la memoria, instancia el nuevo escenario y calcula la entrada del jugador.
func cambiar_mapa(_direction: String, _old_tile_pos: Vector2i):
	var connection = obtener_conexion(_direction)
	if not connection or connection.map_scene_path.is_empty():
		return

	var next_scene = load(connection.map_scene_path) as PackedScene
	if not next_scene:
		return

	# Preparar transición
	player.cancelar_encadenado()
	current_map.queue_free()
	limpiar_vecinos()

	# Cargar nuevo mapa
	current_map = next_scene.instantiate()
	current_map_container.add_child(current_map)

	if not current_map.attributes:
		push_warning("El nuevo mapa no tiene MapAttributes asignado")
		PlayerManager.data.current_map_section = MapSections.SectionID.MAPSEC_NONE
		return

	# Calcular posición
	var new_tile_pos = calcular_posicion_entrada(_direction, _old_tile_pos, current_map.attributes.map_size, connection.offset)
	player.position = tile_a_posicion(new_tile_pos)

	# Guardar datos actualizados
	PlayerManager.data.current_map_scene = current_map.scene_file_path
	PlayerManager.data.grid_position = new_tile_pos
	PlayerManager.data.current_map_section = current_map.attributes.map_section_id

	# Actualizar entorno
	cargar_vecinos()
	MusicManager.reproducir(current_map.attributes.music_path, current_map.attributes.silence_end)
	TimeManager.set_indoors(current_map.attributes.is_indoor)

## Retorna el recurso MapConnection correspondiente a la dirección consultada.
func obtener_conexion(_direction: String) -> MapConnection:
	if not current_map or not current_map.attributes:
		return null

	match _direction:
		"north": return current_map.attributes.north_map
		"east": return current_map.attributes.east_map
		"south": return current_map.attributes.south_map
		"west": return current_map.attributes.west_map
	return null

## Resuelve matemáticamente la coordenada de aparición en el nuevo mapa considerando el offset de costura.
func calcular_posicion_entrada(direction: String, old_tile_pos: Vector2i, new_map_size: Vector2i, offset: Vector2i) -> Vector2i:
	match direction:
		"east":  return Vector2i(0, old_tile_pos.y + offset.y)
		"west":  return Vector2i(new_map_size.x - 1, old_tile_pos.y + offset.y)
		"north": return Vector2i(old_tile_pos.x + offset.x, new_map_size.y - 1)
		"south": return Vector2i(old_tile_pos.x + offset.x, 0)
	return old_tile_pos

## Remueve todos los mapas vecinos instanciados en el contenedor adyacente.
func limpiar_vecinos():
	# Recorremos todos los hijos y los eliminamos de forma segura
	for child in neighbor_map_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
			# También eliminamos la referencia inmediatamente
			neighbor_map_container.remove_child(child)

## Dispara secuencialmente la carga visual de los 4 mapas vecinos posibles.
func cargar_vecinos():
	limpiar_vecinos()
	if not current_map:
		return

	cargar_vecino("north")
	cargar_vecino("east")
	cargar_vecino("south")
	cargar_vecino("west")

## Carga de forma asíncrona/dinámica una escena de mapa vecino y la posiciona correctamente.
func cargar_vecino(direction: String):
	var connection = obtener_conexion(direction)
	if not connection or connection.map_scene_path.is_empty():
		return

	var scene = load(connection.map_scene_path) as PackedScene
	if not scene:
		return

	var neighbor = scene.instantiate() as GameMap
	if not neighbor or not neighbor.attributes:
		if neighbor: neighbor.queue_free()
		return

	neighbor_map_container.add_child(neighbor)

	var current_size_px = Vector2(current_map.attributes.map_size * tile_size)
	var neighbor_size_px = Vector2(neighbor.attributes.map_size * tile_size)
	var offset_px = Vector2(connection.offset * tile_size)

	match direction:
		"east":  neighbor.position = Vector2(current_size_px.x + offset_px.x, offset_px.y)
		"west":  neighbor.position = Vector2(-neighbor_size_px.x + offset_px.x, offset_px.y)
		"north": neighbor.position = Vector2(offset_px.x, -neighbor_size_px.y + offset_px.y)
		"south": neighbor.position = Vector2(offset_px.x, current_size_px.y + offset_px.y)

## Comprueba si el tile destino es una rampa de salto válida.
func es_rampa(player_pos: Vector2, dir: Vector2) -> bool:
	if not current_map:
		return false

	var collision = current_map.behaviours.get_node_or_null("Collision") as TileMapLayer
	if not collision:
		return false

	var current_tile = collision.local_to_map(player_pos)
	var target_tile = current_tile + Vector2i(dir)

	if current_map.has_method("obtener_comportamiento_tile"):
		return current_map.obtener_comportamiento_tile(target_tile) == "saltar_abajo" and dir == Vector2.DOWN

	return false

## Retorna verdadero si el tile destino se puede caminar.
func puede_caminar(player_pos: Vector2, dir: Vector2) -> bool:
	var collision = current_map.behaviours.get_node_or_null("Collision") as TileMapLayer
	if not collision:
		return false

	var current_tile = collision.local_to_map(player_pos)
	var target_tile = current_tile + Vector2i(dir)

	return not current_map.tile_bloqueado(target_tile)

## Convierte posición en píxeles a coordenadas de cuadrícula.
func posicion_a_tile(pos: Vector2) -> Vector2i:
	var adjusted_pos = pos - Vector2(8, 16)
	return Vector2i(floori(adjusted_pos.x / tile_size), floori(adjusted_pos.y / tile_size))

## Ajusta la dirección si se está en una escalera lateral.
func filtrar_direccion_escalera(player_pos: Vector2, dir: Vector2) -> Vector2:
	if not current_map:
		return dir

	var collision = current_map.behaviours.get_node_or_null("Collision") as TileMapLayer
	if not collision:
		return dir

	var current_tile = collision.local_to_map(player_pos)
	if not current_map.has_method("obtener_comportamiento_tile"):
		return dir

	var comportamiento_actual = current_map.obtener_comportamiento_tile(current_tile)

	if comportamiento_actual == "escalera_sube_derecha":
		if dir == Vector2.LEFT:  return Vector2(-1, 1)
		if dir == Vector2.RIGHT: return Vector2(1, -1)
	elif comportamiento_actual == "escalera_sube_izquierda":
		if dir == Vector2.LEFT:  return Vector2(-1, -1)
		if dir == Vector2.RIGHT: return Vector2(1, 1)

	var target_tile = current_tile + Vector2i(dir)
	var comportamiento_destino = current_map.obtener_comportamiento_tile(target_tile)

	if comportamiento_destino == "escalera_sube_derecha":
		if dir == Vector2.RIGHT: return Vector2(1, -1)
		if dir == Vector2.LEFT:  return Vector2(-1, 1)
	elif comportamiento_destino == "escalera_sube_izquierda":
		if dir == Vector2.LEFT:  return Vector2(-1, -1)
		if dir == Vector2.RIGHT: return Vector2(1, 1)

	return dir

## Retorna el tipo de escalera en la posición destino.
func obtener_tipo_escalera(player_pos: Vector2, dir: Vector2) -> String:
	if not current_map:
		return ""

	var collision = current_map.behaviours.get_node_or_null("Collision") as TileMapLayer
	if not collision:
		return ""

	var current_tile = collision.local_to_map(player_pos)
	var target_tile = current_tile + Vector2i(dir)

	if current_map.has_method("obtener_comportamiento_tile"):
		return current_map.obtener_comportamiento_tile(target_tile)

	return ""

func cargar_mapa_desde_guardado() -> void:
	if PlayerManager.data.current_map_scene.is_empty():
		push_warning("No hay ruta de mapa guardada")
		return

	var nueva_escena = load(PlayerManager.data.current_map_scene) as PackedScene
	if not nueva_escena:
		return

	# 🧹 LIMPIEZA TOTAL ANTES DE CARGAR NADA NUEVO
	# Eliminar mapa actual si existe
	if current_map and is_instance_valid(current_map):
		current_map.queue_free()
		current_map = null

	# Limpiar contenedor principal
	for child in current_map_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
			current_map_container.remove_child(child)

	# Limpiar contenedor de vecinos también
	limpiar_vecinos()

	# Esperar un frame para que Godot borre todo completamente
	await get_tree().process_frame

	# 🗺️ Ahora sí cargamos el mapa guardado
	current_map = nueva_escena.instantiate()
	current_map_container.add_child(current_map)

	if current_map.attributes:
		MusicManager.reproducir(current_map.attributes.music_path, current_map.attributes.silence_end)
		TimeManager.set_indoors(current_map.attributes.is_indoor)
		PlayerManager.data.current_map_section = current_map.attributes.map_section_id

	cargar_vecinos()

	# Aplicar posición correctamente
	await get_tree().process_frame

	if player and is_instance_valid(player):
		player.position = tile_a_posicion(PlayerManager.data.grid_position)
		player.direccion = PlayerManager.data.direction
		print("📍 Mapa y posición cargados limpiamente desde guardado")
