@tool
extends Node2D
class_name GameMap

## Tamaño del mapa en baldosas
@export var map_size: Vector2i = Vector2i(20, 20):
	set(new_val):
		map_size = new_val
		queue_redraw()
		_actualizar_vista()

## Tamaño en píxeles de cada baldosa
@export var tile_size: int = 16:
	set(new_val):
		tile_size = new_val
		queue_redraw()
		_actualizar_vista()

## Recurso con conexiones y datos
@export var attributes: MapAttributes:
	set(new_attr):
		# 🛑 PRIMERO: Desconectamos la señal del recurso anterior si existía
		if attributes:
			if attributes.changed.is_connected(_actualizar_vista):
				attributes.changed.disconnect(_actualizar_vista)

		attributes = new_attr

		# ✅ AHORA: Conectamos la señal al nuevo recurso solo si no está conectada
		if attributes:
			if not attributes.changed.is_connected(_actualizar_vista):
				attributes.changed.connect(_actualizar_vista)

		_actualizar_vista()

## Activar/desactivar vista previa
@export var ver_vecinos_en_editor: bool = true:
	set(new_val):
		ver_vecinos_en_editor = new_val
		_actualizar_vista()

@onready var behaviours: Node2D = $Behaviours

# Control para evitar bucles infinitos
var _es_vista_previa: bool = false
var _editor_neighbors_container: Node2D = null
var _necesita_actualizar: bool = false


func _ready() -> void:
	if _es_vista_previa:
		process_mode = Node.PROCESS_MODE_DISABLED # Asegura que no ejecute código
		return

	if not Engine.is_editor_hint():
		var collision = behaviours.get_node_or_null("Collision") as TileMapLayer
		if collision:
			collision.visible = false
		
		if TimeManager.has_method("activar"):
			TimeManager.activar()
		return

	if not _editor_neighbors_container:
		_editor_neighbors_container = Node2D.new()
		_editor_neighbors_container.name = "EditorNeighbors"
		add_child(_editor_neighbors_container)

		if attributes:
			if not attributes.changed.is_connected(_actualizar_vista):
				attributes.changed.connect(_actualizar_vista)

	_actualizar_vista()

# Solo en editor: procesamos actualizaciones pendientes
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not _es_vista_previa and _necesita_actualizar:
		actualizar_visualizacion_vecinos()
		_necesita_actualizar = false


func _draw():
	if not Engine.is_editor_hint():
		return
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(map_size * tile_size)),
		Color.RED,
		false,
		2.0
	)


# Función auxiliar: marca que hay cambios
func _actualizar_vista() -> void:
	if Engine.is_editor_hint() and not _es_vista_previa:
		_necesita_actualizar = true


func actualizar_visualizacion_vecinos() -> void:
	if not Engine.is_editor_hint() or not _editor_neighbors_container or _es_vista_previa:
		return

	for child in _editor_neighbors_container.get_children():
		child.queue_free()

	if not ver_vecinos_en_editor or not attributes:
		return

	var tamaño_actual_px = Vector2(map_size * tile_size)

	cargar_y_posicionar_vecino("north", attributes.north_map, tamaño_actual_px)
	cargar_y_posicionar_vecino("east", attributes.east_map, tamaño_actual_px)
	cargar_y_posicionar_vecino("south", attributes.south_map, tamaño_actual_px)
	cargar_y_posicionar_vecino("west", attributes.west_map, tamaño_actual_px)


func cargar_y_posicionar_vecino(direccion: String, conexion: MapConnection, tamaño_actual_px: Vector2) -> void:
	if not conexion or conexion.map_scene_path.is_empty():
		return

	var escena_vecina = load(conexion.map_scene_path) as PackedScene
	if not escena_vecina:
		return

	var mapa_vecino = escena_vecina.instantiate() as GameMap
	if not mapa_vecino:
		return

	# 🚫 MARCAMOS Y BLOQUEAMOS TODO LO QUE NO SEA VISUAL
	mapa_vecino._es_vista_previa = true
	mapa_vecino.modulate.a = 0.55
	mapa_vecino.set_owner(null)
	mapa_vecino.process_mode = Node.PROCESS_MODE_DISABLED # Desactivamos su lógica

	var tamaño_vecino_px = Vector2(mapa_vecino.map_size * tile_size)
	var offset_px = Vector2(conexion.offset * tile_size)

	match direccion:
		"north":
			mapa_vecino.position = Vector2(offset_px.x, -tamaño_vecino_px.y + offset_px.y)
		"south":
			mapa_vecino.position = Vector2(offset_px.x, tamaño_actual_px.y + offset_px.y)
		"east":
			mapa_vecino.position = Vector2(tamaño_actual_px.x + offset_px.x, offset_px.y)
		"west":
			mapa_vecino.position = Vector2(-tamaño_vecino_px.x + offset_px.x, offset_px.y)

	_editor_neighbors_container.add_child(mapa_vecino)


# --- Funciones originales ---
func tile_bloqueado(tile_pos: Vector2i) -> bool:
	for child in behaviours.get_children():
		if child is TileMapLayer:
			var data = child.get_cell_tile_data(tile_pos)
			if data and data.get_custom_data("blocked"):
				return true
	return false

func obtener_comportamiento_tile(tile_pos: Vector2i) -> String:
	for child in behaviours.get_children():
		if child is TileMapLayer:
			var data = child.get_cell_tile_data(tile_pos)
			if data:
				var c = data.get_custom_data("comportamiento")
				if c != "": return c
	return ""
