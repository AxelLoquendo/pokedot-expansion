extends Area2D

const FRAME_COUNT = 16
const TILE_SIZE = 32
const WALK_SPEED = TILE_SIZE/float(FRAME_COUNT)
const FRAMES_PER_STEP = FRAME_COUNT/4

var frame_timer := 0
var facing_direction := Vector2.DOWN
var is_walking := false
var has_encounter := false

@onready var ray_cast_2d: RayCast2D = $CollisionShape2D/Node2D/RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D

signal interact(message: String)

func _ready() -> void:
	#fix pos
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))

func _physics_process(_delta: float) -> void:
	var input_direction = _get_locked_input()

	if is_walking:
		_advance_walk_animation()
	elif input_direction != Vector2.ZERO:
		if input_direction != facing_direction:
			facing_direction = input_direction
			$CollisionShape2D.rotation_degrees = _get_rotation_by_dir(facing_direction)
			sprite_2d.frame = _get_base_frame(facing_direction)
			return
		if _is_move_blocked():
			return
		
		position += facing_direction * Vector2(TILE_SIZE, TILE_SIZE)
		sprite_2d.position -= facing_direction * Vector2(TILE_SIZE, TILE_SIZE)
		is_walking = true

func _is_move_blocked() -> bool:
	var collider := ray_cast_2d.get_collider()
	if not collider:
		return false

	var tile_map := collider as TileMapLayer

	if not tile_map:
		return true

	#var collision_point := ray_cast_2d.get_collision_point()
	var collision_point := global_position + facing_direction * Vector2(TILE_SIZE, TILE_SIZE)

	var local_pos := tile_map.to_local(collision_point)
	var tile_coords := tile_map.local_to_map(local_pos)
	
	var tile_data := tile_map.get_cell_tile_data(tile_coords)
	if tile_data and tile_data.get_custom_data("tall_grass"):
		if randi_range(0, 255) > 37:
			has_encounter = true
		return false
	return true

func _get_locked_input() -> Vector2:
	var x = Input.get_axis("ui_left", "ui_right")
	var y = Input.get_axis("ui_up", "ui_down")
	if x != 0 and y != 0:
		x = 0
	return Vector2(x, y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		var collider = ray_cast_2d.get_collider() as Area2D
		if collider != null:
			var interactive = collider.get_node_or_null("Interactive")
			
			if interactive:
				interact.emit(interactive.message)
				get_viewport().set_input_as_handled()

func _advance_walk_animation() -> void:
	frame_timer += 1

	if frame_timer > FRAME_COUNT:
		frame_timer = 0
		is_walking = false
		sprite_2d.frame = _get_base_frame(facing_direction)
		
		if has_encounter:
			$"../..".call_deferred("start_battle")
			has_encounter = false
		return

	var step = _get_step_by_frame(frame_timer)
	sprite_2d.frame = _get_base_frame(facing_direction) + step
	sprite_2d.position += facing_direction * WALK_SPEED

func _get_step_by_frame(frame_timer: int) -> int:
	if frame_timer <= FRAMES_PER_STEP:
		return 0
	if frame_timer <= FRAMES_PER_STEP * 2:
		return 1
	if frame_timer <= FRAMES_PER_STEP * 3:
		return 2
	if frame_timer <= FRAMES_PER_STEP * 4:
		return 3
	return 0

func _get_base_frame(direction: Vector2) -> int:
	match direction:
		Vector2.DOWN:
			return 0
		Vector2.LEFT:
			return 4
		Vector2.RIGHT:
			return 8
		Vector2.UP:
			return 12
		_:
			return 0

func _get_rotation_by_dir(direction: Vector2) -> int:
	match direction:
		Vector2.DOWN:
			return 0
		Vector2.LEFT:
			return 90
		Vector2.RIGHT:
			return -90
		Vector2.UP:
			return 180
		_:
			return 0
