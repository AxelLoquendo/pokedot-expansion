extends TileMapLayer

@export var map: GameMap
@export var border_width: int = 4
@export var border_block_size: Vector2i = Vector2i(1, 1)
@export var source_id: int = 0
@export var border_atlas_origin: Vector2i = Vector2i(0, 0)

func _ready():
	generar_borde()

func generar_borde():
	if map == null:
		push_warning("Border: no hay mapa asignado.")
		return

	if map.attributes == null:
		push_warning("Border: el mapa no tiene attributes.")
		return

	clear()

	var size: Vector2i = map.attributes.map_size

	for x in range(-border_width, size.x + border_width):
		for y in range(-border_width, size.y + border_width):
			var tile_pos := Vector2i(x, y)
			var dentro_del_mapa := x >= 0 and x < size.x and y >= 0 and y < size.y

			if dentro_del_mapa:
				continue

			if esta_en_lado_conectado(tile_pos, size):
				continue

			var local_x := posmod(x, border_block_size.x)
			var local_y := posmod(y, border_block_size.y)

			var atlas_coords := border_atlas_origin + Vector2i(local_x, local_y)

			set_cell(tile_pos, source_id, atlas_coords)

func esta_en_lado_conectado(tile_pos: Vector2i, size: Vector2i) -> bool:
	if map.attributes.north_map != null and tile_pos.y < 0 and tile_pos.x >= 0 and tile_pos.x < size.x:
		return true

	if map.attributes.south_map != null and tile_pos.y >= size.y and tile_pos.x >= 0 and tile_pos.x < size.x:
		return true

	if map.attributes.west_map != null and tile_pos.x < 0 and tile_pos.y >= 0 and tile_pos.y < size.y:
		return true

	if map.attributes.east_map != null and tile_pos.x >= size.x and tile_pos.y >= 0 and tile_pos.y < size.y:
		return true

	return false
