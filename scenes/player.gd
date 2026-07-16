extends CharacterBody2D

const WALK_SPEED = 2
const FRAMES_PER_STEP = 4
const FRAME_COUNT = 16
const TILE_SIZE = 32

var frame_timer := 0
var facing_direction := Vector2.DOWN
var is_walking := false

func _ready() -> void:
	#fix pos
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))

func _physics_process(_delta: float) -> void:
	var input_direction = _get_locked_input()

	if is_walking:
		_advance_walk_animation()
	elif input_direction != Vector2.ZERO:
		facing_direction = input_direction
		is_walking = true

func _get_locked_input() -> Vector2:
	var x = Input.get_axis("ui_left", "ui_right")
	var y = Input.get_axis("ui_up", "ui_down")
	if x != 0 and y != 0:
		x = 0
	return Vector2(x, y)


func _advance_walk_animation() -> void:
	frame_timer += 1

	if frame_timer > FRAME_COUNT:
		frame_timer = 0
		is_walking = false
		$Sprite2D.frame = _get_base_frame(facing_direction)
		return

	var step = _get_step_by_frame(frame_timer)
	$Sprite2D.frame = _get_base_frame(facing_direction) + step
	position += facing_direction * WALK_SPEED
	move_and_slide()

func _get_step_by_frame(frame_timer: int) -> int:
	match frame_timer:
		1, 2, 3, 4:
			return 0
		5, 6, 7, 8:
			return 1
		9, 10, 11, 12:
			return 2
		13, 14, 15, 16:
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
