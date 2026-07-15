extends Sprite2D

# El cordenadas del sprites se encuentra en el medio del sprite

const TILE_SIZE: int = 32
const MOVE_FRAMES: float = 16.0
const MOVE_DURATION: float = MOVE_FRAMES / 60.0
const FRAME_RATE: float = 60.0

var is_moving: bool = false
var current_direction = Vector2.DOWN

func _ready() -> void:
	hframes = 4
	vframes = 4
	frame = 0
	# Las coodernadas del sprites se deben encontrar en la mitad del tile
	# dando que esta centrado
	var sprite_off_set = Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	global_position = global_position.snapped(Vector2(TILE_SIZE, TILE_SIZE)) - sprite_off_set

func _process(_delta: float) -> void:
	var sprite_off_set = Vector2(TILE_SIZE, TILE_SIZE) * 0.5
	if is_moving:
		return
	_process_input()

# Este nombre no me gusta nada
func move(start: Vector2, target: Vector2, lerp: float):
	global_position = start.lerp(target, lerp / 16.0)
	if lerp == 16.0:
		global_position = target

	var anim_seq = int(lerp / 4.0) if lerp != 16.0 else 0
	frame = _get_frame_by_direction(current_direction) + anim_seq


func _process_input() -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("ui_up"):
		direction = Vector2.UP

	if direction == Vector2.ZERO:
		return
	
	# Ventana de cambio de direccion
	if direction != current_direction:
		current_direction = direction
		frame = _get_frame_by_direction(current_direction)
		is_moving = true
		get_tree().create_timer(5 / FRAME_RATE).timeout.connect(func(): is_moving = false)
		return

	var target_global := global_position + direction * TILE_SIZE
	var validated = get_parent().get_validated_move(target_global)
	var start = global_position

	if validated != Vector2.INF:
		create_tween() \
				.tween_method(func(lerp): move(start, validated, lerp), 0.0, MOVE_FRAMES, MOVE_DURATION) \
				.finished.connect(func(): is_moving = false)
		is_moving = true


func _get_frame_by_direction(vec: Vector2):
	match current_direction:
		Vector2.DOWN:
			return 0
		Vector2.LEFT:
			return 4
		Vector2.RIGHT:
			return 8
		Vector2.UP:
			return 12
	assert("No deberia llegar hasta este punto")
