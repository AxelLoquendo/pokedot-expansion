extends Node

@onready var map: Node2D = $Map
@onready var ground_layer: TileMapLayer = map.get_child(0)
@onready var collision_layer: TileMapLayer = map.get_child(1)

func get_validated_move(target_global_pos: Vector2) -> Vector2:
	var local_pos: Vector2 = ground_layer.to_local(target_global_pos)
	var tile_coords: Vector2i = ground_layer.local_to_map(local_pos)
	
	if collision_layer.get_cell_source_id(tile_coords) != -1:
		return Vector2.INF
	
	var snapped_local: Vector2 = ground_layer.map_to_local(tile_coords)
	return ground_layer.to_global(snapped_local)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
