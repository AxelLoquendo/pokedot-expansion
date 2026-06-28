@tool
extends Node2D

## Clase base que representa un mapa individual del juego.
## Maneja los límites lógicos, propiedades de tamaño y la consulta de colisiones/eventos.
class_name GameMap
## Tamaño del mapa medido en cantidad de baldosas (tiles).
@export var map_size: Vector2i = Vector2i(20, 20):
	set(value):
		map_size = value
		queue_redraw()# Redibuja el cuadro rojo en el editor si cambia el tamaño
## Tamaño en píxeles de cada baldosa individual (por defecto 16x16).
@export var tile_size := 16:
	set(value):
		tile_size = value
		queue_redraw()# Redibuja el cuadro rojo en el editor si cambia el tamaño
## Dibuja un rectángulo rojo que delimita el tamaño del mapa únicamente dentro del editor de Godot.
func _draw():
	# Si el juego se está ejecutando, no dibuja nada en la pantalla
	if not Engine.is_editor_hint():
		return
	# Dibuja el borde exterior del mapa basado en el tamaño total en píxeles
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(map_size * tile_size)),
		Color.RED,
		false,# False para que solo sea un borde y no un cuadro relleno
		2.0 # Grosor de la línea del borde
	)
## Recurso personalizado que almacena la información y conexiones lógicas de este mapa.
@export var attributes: MapAttributes
## Contenedor que agrupa las distintas capas lógicas (TileMapLayers) como Colisiones o Eventos.
@onready var behaviours: Node2D = $Behaviours

func _ready():
	# Busca la capa de colisión por defecto y la oculta al iniciar el juego
	# Esto permite pintar con colores lógicos en el editor sin que el jugador los vea en el gameplay
	var collision := behaviours.get_node("Collision") as TileMapLayer
	collision.visible = false
	#print("Map de (88,96): ", collision.local_to_map(Vector2(88,96)))
	#print("Map de (88,112): ", collision.local_to_map(Vector2(88,112)))
## Evalúa si una coordenada específica de la cuadrícula está obstruida.
## Recorre todas las capas dentro de Behaviours buscando la propiedad personalizada "blocked".
func tile_bloqueado(tile_pos: Vector2i) -> bool:
	#print("=== CONSULTANDO === ", tile_pos)

	for child in behaviours.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer

			var data := layer.get_cell_tile_data(tile_pos)
			# Si la capa no contiene un tile en esa posición, pasa a la siguiente capa
			if data == null:
				continue

			#print(
			#	"Celda:", tile_pos,
			#	" Source:", layer.get_cell_source_id(tile_pos),
			#	" Atlas:", layer.get_cell_atlas_coords(tile_pos),
			#	" Blocked:", data.get_custom_data("blocked")
			#)
			# Si el tile tiene la casilla 'blocked' en true, confirma el bloqueo
			if data.get_custom_data("blocked"):
				return true

	return false # El camino está libre si ninguna capa reporta un bloqueo

## Busca y devuelve el identificador de acción o comportamiento de un tile (ej: "saltar_abajo", "hierba").
## Recorre las capas dentro de Behaviours y extrae el texto de la capa personalizada "comportamiento".
func obtener_comportamiento_tile(tile_pos: Vector2i) -> String:
	for child in behaviours.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer
			var data := layer.get_cell_tile_data(tile_pos)
			# Si la capa no contiene un tile en esa posición, continúa buscando en las demás
			if data == null:
				continue

			# Retorna el string del comportamiento solo si contiene texto válido
			var comportamiento = data.get_custom_data("comportamiento")
			if comportamiento != "":
				return comportamiento

	return "" # Devuelve un texto vacío si el tile no tiene ninguna acción especial asignada
