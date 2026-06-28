extends Node
## Clase administradora global del entorno.
## Controla la carga y descarga de mapas, la costura de mapas vecinos en tiempo real,
## las posiciones relativas del jugador y el puente lógico para colisiones y eventos.
class_name MapManager

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
	cargar_mapa_inicial()
	# Configura la posición inicial del jugador y conecta la señal de movimiento completado
	if player != null:
		player.position = tile_a_posicion(initial_player_tile)
		player.paso_terminado.connect(_on_player_paso_terminado)
## Se ejecuta automáticamente cada vez que el jugador termina de dar un paso completo.
func _on_player_paso_terminado():
	revisar_salida_del_mapa()
## Instancia y añade el mapa base al contenedor principal al arrancar el juego.
func cargar_mapa_inicial():
	if initial_map == null:
		return
		
	current_map = initial_map.instantiate()
	current_map_container.add_child(current_map)
	cargar_vecinos()
## Comprueba si el jugador ha cruzado los límites lógicos del mapa actual (Norte, Sur, Este, Oeste).
func revisar_salida_del_mapa():
	if current_map == null:
		return
	
	if current_map.attributes == null:
		push_warning("El mapa actual no tiene MapAttributes asignado.")
		return
	
	var _tile_pos := posicion_a_tile(player.position)
	
	var size := current_map.attributes.map_size
	# Verifica si la coordenada se salió de los límites de la matriz del mapa actual
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
	var connection := obtener_conexion(_direction)
	
	if connection == null:
		return
	
	if connection.map_scene_path.is_empty():
		return

	var next_scene := load(connection.map_scene_path) as PackedScene

	if next_scene == null:
		return
	# Cancela el encadenamiento de pasos del jugador durante la transición
	player.cancelar_encadenado()
	# Elimina el mapa actual y limpia visualmente las costuras adyacentes
	current_map.queue_free()
	limpiar_vecinos()
	# Carga e instancia el nuevo mapa de la conexión
	current_map = next_scene.instantiate()
	current_map_container.add_child(current_map)

	if current_map.attributes == null:
		push_warning("El nuevo mapa no tiene MapAttributes asignado.")
		return
	# Calcula en qué tile exacto del nuevo mapa debe aparecer el personaje
	var new_tile_pos := calcular_posicion_entrada(
		_direction,
		_old_tile_pos,
		current_map.attributes.map_size,
		connection.offset
	)
	# Ubica al jugador en su nueva posición física y regenera las cargas de mapas vecinos
	player.position = tile_a_posicion(new_tile_pos)
	cargar_vecinos()
## Retorna el recurso MapConnection correspondiente a la dirección consultada.
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
## Resuelve matemáticamente la coordenada de aparición en el nuevo mapa considerando el offset de costura.
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
## Remueve todos los mapas vecinos instanciados en el contenedor adyacente.
func limpiar_vecinos():
	for child in neighbor_map_container.get_children():
		child.queue_free()
## Dispara secuencialmente la carga visual de los 4 mapas vecinos posibles.
func cargar_vecinos():
	limpiar_vecinos()

	if current_map == null:
		return

	cargar_vecino("north")
	cargar_vecino("east")
	cargar_vecino("south")
	cargar_vecino("west")
## Carga de forma asíncrona/dinámica una escena de mapa vecino y la posiciona 
## de forma milimétrica en los bordes en píxeles del mapa central usando su offset.
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
	# Dimensiones en píxeles para calcular las posiciones de renderizado de los vecinos
	var current_size_px := Vector2(current_map.attributes.map_size * tile_size)
	var neighbor_size_px := Vector2(neighbor.attributes.map_size * tile_size)
	var offset_px := float(connection.offset * tile_size)
	# Desplaza los nodos geográficamente en el viewport del motor para encajarlos perfectamente
	match direction:
		"east":
			neighbor.position = Vector2(current_size_px.x, -offset_px)
		"west":
			neighbor.position = Vector2(-neighbor_size_px.x, -offset_px)
		"north":
			neighbor.position = Vector2(-offset_px, -neighbor_size_px.y)
		"south":
			neighbor.position = Vector2(-offset_px, current_size_px.y)

## Intercepta las colisiones para comprobar si un obstáculo frontal es una rampa de salto válida.
## Usa el convertidor nativo de TileMapLayer para garantizar la precisión de la baldosa.
func es_rampa(player_pos: Vector2, dir: Vector2) -> bool:
	if current_map == null:
		return false

	var collision := current_map.behaviours.get_node("Collision") as TileMapLayer
	if collision == null:
		return false

	# Obtiene las coordenadas nativas de la celda actual y la celda objetivo
	var current_tile := collision.local_to_map(player_pos)
	var target_tile := current_tile + Vector2i(dir)

	# Consulta al mapa si existe algún metadato de comportamiento asignado
	if current_map.has_method("obtener_comportamiento_tile"):
		var comportamiento = current_map.obtener_comportamiento_tile(target_tile)
		
		# Mantengo el print de diagnóstico solo para que verifiques en consola
		#print("--- NUEVO DIAGNÓSTICO EN (", target_tile.x, ", ", target_tile.y, ") ---")
		#print("Comportamiento detectado: '", comportamiento, "'")
		# Filtra si el tile es rampa de bajada y el jugador se mueve en el eje vertical inferior
		if comportamiento == "saltar_abajo" and dir == Vector2.DOWN:
			return true

	return false
## Retorna verdadero si el tile destino no posee el flag "blocked".
## Sirve como el validador principal del movimiento del jugador por cuadrículas.
func puede_caminar(player_pos: Vector2, dir: Vector2) -> bool:
	var collision := current_map.behaviours.get_node("Collision") as TileMapLayer
	var current_tile := collision.local_to_map(player_pos)
	var target_tile := current_tile + Vector2i(dir)

	#print("Pos:", player_pos)
	#print("Current:", current_tile)
	#print("Target:", target_tile)

	return not current_map.tile_bloqueado(target_tile)
## Traduce una posición en píxeles del mundo global a coordenadas de la cuadrícula.
## Resta el desfase de (8, 16) para compensar el pivote visual del personaje.
func posicion_a_tile(pos: Vector2) -> Vector2i:
	var adjusted_pos := pos - Vector2(8, 16)

	return Vector2i(
		floori(adjusted_pos.x / tile_size),
		floori(adjusted_pos.y / tile_size)
	)
