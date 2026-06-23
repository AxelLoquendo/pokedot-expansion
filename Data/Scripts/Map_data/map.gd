@tool
extends Node2D

class_name GameMap

@export var map_size: Vector2i = Vector2i(20, 20):
	set(value):
		map_size = value
		queue_redraw()

@export var tile_size := 16:
	set(value):
		tile_size = value
		queue_redraw()

func _draw():
	if not Engine.is_editor_hint():
		return

	draw_rect(
		Rect2(Vector2.ZERO, Vector2(map_size * tile_size)),
		Color.RED,
		false,
		2.0
	)

@export var attributes: MapAttributes

@onready var behaviours: Node2D = $Behaviours

func _ready():
	var collision := behaviours.get_node("Collision") as TileMapLayer
	collision.visible = false
	#print("Map de (88,96): ", collision.local_to_map(Vector2(88,96)))
	#print("Map de (88,112): ", collision.local_to_map(Vector2(88,112)))

func tile_bloqueado(tile_pos: Vector2i) -> bool:
	#print("=== CONSULTANDO === ", tile_pos)

	for child in behaviours.get_children():
		if child is TileMapLayer:
			var layer := child as TileMapLayer

			var data := layer.get_cell_tile_data(tile_pos)

			if data == null:
				continue

			#print(
			#	"Celda:", tile_pos,
			#	" Source:", layer.get_cell_source_id(tile_pos),
			#	" Atlas:", layer.get_cell_atlas_coords(tile_pos),
			#	" Blocked:", data.get_custom_data("blocked")
			#)

			if data.get_custom_data("blocked"):
				return true

	return false
