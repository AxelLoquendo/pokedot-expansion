extends Node2D

enum TileType {
	NONE,
	GRASS,
}

@onready var game: Node = $".."


var tile_data_by_cell: Dictionary


func _ready() -> void:
	var children := $Map.get_children()
	for child in children:
		if not child is TileMapLayer:
			continue
			
		var layer := child as TileMapLayer
		var used_cells := layer.get_used_cells()

		for used_cell in used_cells:
			var tile_data := layer.get_cell_tile_data(used_cell)

			tile_data_by_cell[used_cell] = tile_data


func _on_player_entered_tile(local_position: Vector2i) -> void:
	var coords = $Map.get_child(0).local_to_map(local_position)
	var tile_data: TileData = tile_data_by_cell.get(coords, null)
	
	if not tile_data:
		return
		
	if tile_data.get_custom_data("tile_type") == TileType.GRASS:
		if randi_range(0, 255) < 47:
			game.start_battle()
