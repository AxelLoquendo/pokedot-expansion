extends CharacterBody2D

signal paso_terminado
var puede_encadenar_paso := true

@export var duracion_paso: float = 0.30
@export var tile_block: int = 16
@export var velocidad_animacion: float = 0.75
@export var tiempo_para_caminar: float = 0.12
@export var map_manager: MapManager

var moviendose := false
var posicion_inicio: Vector2
var posicion_obj: Vector2
var tiempo_paso := 0.0
var direccion := Vector2.DOWN

var direccion_input := Vector2.ZERO
var tiempo_input := 0.0

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var dir_to_anim: Dictionary = {
	Vector2.UP: "up",
	Vector2.DOWN: "down",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}
#funciòn de inicio donde se define la posicion del objetivo y se iguala a la posicion para luego llamar a la funcion de mostrar idle con la variable direccion.
func _ready():
	posicion_obj = position
	mostrar_idle(direccion)
#funcion donde se maneja la fisica en la cual se verifica si el jugador se esta moviendo, si es asi, se llama la funcion actualizar movimiento, de lo contrario llamamos la funcion que maneja la input estando quieto.
func _physics_process(delta):
	if moviendose:
		actualizar_movimiento(delta)
	else:
		manejar_input_quieto(delta)
#la funcion actualiza el movimiento del jugador definiendo el tiempo que dura en dar un paso, teniendo como variable "t" que seria igual al tiempo de paso entre la duracion del paso.
#si t es menor a 1.0 se regresa y se da por hecho de que esta quieto, de lo contrario se sigue la verificacion del movimiento mecanicamente.
func actualizar_movimiento(delta: float):
	tiempo_paso += delta

	var t: float = tiempo_paso / duracion_paso
	t = clamp(t, 0.0, 1.0)

	position = posicion_inicio.lerp(posicion_obj, t)

	if t < 1.0:
		return

	position = posicion_obj
	moviendose = false
	puede_encadenar_paso = true
	
	paso_terminado.emit()
	
	if not puede_encadenar_paso:
		mostrar_idle(direccion)
		return

	var dir := obtener_direccion_input()

	if dir != Vector2.ZERO:
		empezar_paso(dir)
	else:
		mostrar_idle(direccion)
#esta funcion maneja el input del jugador estando quieto, obteniendo la ultima direccion de este y posicionando la sprite a un frame donde este mirando en esa direccion.
func manejar_input_quieto(delta: float):
	var dir := obtener_direccion_input()

	if dir == Vector2.ZERO:
		direccion_input = Vector2.ZERO
		tiempo_input = 0.0
		mostrar_idle(direccion)
		return

	if dir != direccion:
		mirar_hacia(dir)
		direccion_input = dir
		tiempo_input = 0.0
		return

	if dir != direccion_input:
		direccion_input = dir
		tiempo_input = 0.0

	tiempo_input += delta

	if tiempo_input >= tiempo_para_caminar:
		empezar_paso(dir)
#esta funcion da inicio a caminar, moviendo al jugador conforme a la direccion
func empezar_paso(dir: Vector2):
	# Comprobación de colisión
	#print("MapManager:", map_manager)
	if map_manager != null and not map_manager.puede_caminar(position, dir):
		mostrar_idle(direccion)
		return
	
	direccion = dir
	direccion_input = dir
	tiempo_input = 0.0

	posicion_inicio = position
	posicion_obj = position + dir * tile_block
	tiempo_paso = 0.0
	moviendose = true

	reproducir_caminata(dir)
#gira al personaje jugable a la direccion correspondiente al presionar rapidamente un boton de movimiento
func mirar_hacia(dir: Vector2):
	direccion = dir
	mostrar_idle(dir)
#se encarga de llamar la funcion que obtiene la animacion y reproduce la animacion del jugador caminando
func reproducir_caminata(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation == anim_name and anim_player.is_playing():
		return

	anim_player.speed_scale = velocidad_animacion
	anim_player.play(anim_name)
#muestra lo que seria el frame del jugador cuando esta quieto
func mostrar_idle(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation != anim_name:
		anim_player.speed_scale = 1.0
		anim_player.play(anim_name)

	anim_player.seek(0.0, true)
	anim_player.pause()
#obtiene la animacion del jugador
func obtener_animacion(tipo: String, dir: Vector2) -> String:
	return tipo + "_" + String(dir_to_anim[dir])
#obtiene la direccion input, o sea, recibe las señales de los controles definidos y mueve al jugador en direccion al vector resultante
func obtener_direccion_input() -> Vector2:
	if Input.is_action_pressed("Up"):
		return Vector2.UP
	elif Input.is_action_pressed("Down"):
		return Vector2.DOWN
	elif Input.is_action_pressed("Left"):
		return Vector2.LEFT
	elif Input.is_action_pressed("Right"):
		return Vector2.RIGHT

	return Vector2.ZERO
#cancela la caminata si hay un obstaculo
func cancelar_encadenado():
	puede_encadenar_paso = false
