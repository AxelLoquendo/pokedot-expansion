extends Area2D

const FRAME_COUNT = 32
const TILE_SIZE = 32
const WALK_SPEED = TILE_SIZE/float(FRAME_COUNT)
const FRAMES_PER_STEP = FRAME_COUNT/4

var frame_timer := 0
var facing_direction := Vector2.DOWN
var is_walking := false
var rice_index := 0
var rice := [Vector2.RIGHT, Vector2.RIGHT, Vector2.RIGHT, Vector2.LEFT, Vector2.LEFT, Vector2.LEFT]

@onready var ray_cast_2d: RayCast2D = $CollisionShape2D/Node2D/RayCast2D
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	#fix pos
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))

func _get_locked_input() -> Vector2:
	if rice_index == rice.size():
		rice_index = 0
	return rice[rice_index]

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
		if ray_cast_2d.is_colliding():
			return
			
		position += facing_direction * Vector2(TILE_SIZE, TILE_SIZE)
		sprite_2d.position -= facing_direction * Vector2(TILE_SIZE, TILE_SIZE)
		is_walking = true


func _advance_walk_animation() -> void:
	frame_timer += 1

	if frame_timer > FRAME_COUNT:
		frame_timer = 0
		rice_index += 1
		is_walking = false
		sprite_2d.frame = _get_base_frame(facing_direction)
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
