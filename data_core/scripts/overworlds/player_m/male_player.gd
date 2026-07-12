extends CharacterBody2D

## Clase controladora del personaje jugable (Movimiento por cuadrículas estilo RPG clásico).
## Administra los inputs de dirección, estados de caminata, colisiones lógicas,
## menús de interfaz y animaciones interpoladas por baldosas.

var start_menu: Node = null

signal paso_terminado
var puede_encadenar_paso := true

@export_group("Configuración de Movimiento")
@export var duracion_paso: float = 0.30
@export var tile_block: int = 16
@export var velocidad_animacion: float = 0.75
@export var tiempo_para_caminar: float = 0.12
@export var map_manager: MapManager

# Estado interno
var moviendose := false
var posicion_inicio: Vector2
var posicion_obj: Vector2
var tiempo_paso := 0.0
var direccion: Vector2 = Vector2.DOWN
var direccion_input: Vector2 = Vector2.ZERO
var tiempo_input := 0.0

# Referencias pre-cargadas
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx_bump: AudioStreamPlayer = $SfxBump
@onready var sfx_jump: AudioStreamPlayer = $SfxJump

# Constantes
const DIR_TO_ANIM: Dictionary = {
	Vector2.UP: "up",
	Vector2.DOWN: "down",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}
const MENU_ESCENA: PackedScene = preload("res://scenes/menus/start_menu/start_menu.tscn")


func _ready() -> void:
	if PlayerManager.data.current_map_scene != "":
		aplicar_datos_guardados()
	else:
		posicionar_en_casilla(7, 10)
		direccion = Vector2.DOWN
	
	posicion_obj = position
	mostrar_idle(direccion)

	# ⚠️ Solo para pruebas — quitar o comentar en versión final
	_agregar_pokemon_prueba()


func _process(_delta: float) -> void:
	if DialogueManager.activo:
		return

	# Ahora sí: si presionas "Abrir", alterna abrir/cerrar
	if Input.is_action_just_pressed("Abrir"):
		toggle_menu()


func _physics_process(delta: float) -> void:
	if DialogueManager.activo or (start_menu and start_menu.is_open):
		velocity = Vector2.ZERO
		return

	if moviendose:
		actualizar_movimiento(delta)
	else:
		manejar_input_quieto(delta)


func _input(event: InputEvent) -> void:
	# Bloquear todo input si hay diálogo
	if DialogueManager.activo:
		if event.is_action_pressed("Interactuar"):
			DialogueManager.entrada_avanzar()
			get_viewport().set_input_as_handled()
		return

	# Teclas de prueba
	# Teclas de prueba
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_G: SaveBlock.guardar_partida()   # 🌟 Al ir vacío (-1), usará la ranura de la RAM
			KEY_C: SaveBlock.cargar_partida()    # 🌟 Lo mismo para cargar
			KEY_T: DialogueManager.mostrar([
				"¡Bienvenido al mundo Pokémon!",
				"Estás usando Pokedot-Expansion",
				"¿Dónde estoy?"
			])
			KEY_F5: SaveBlock.guardar_partida()  # 🌟 Corregido
			KEY_F9: SaveBlock.cargar_partida()   # 🌟 Corregido


## Alterna apertura/cierre del menú
func toggle_menu() -> void:
	if start_menu:
		cerrar_menu()
	else:
		abrir_menu()


func abrir_menu() -> void:
	start_menu = MENU_ESCENA.instantiate()
	get_tree().current_scene.add_child(start_menu)
	start_menu.toggle_menu()


func cerrar_menu() -> void:
	if start_menu:
		start_menu.queue_free()
		start_menu = null


func actualizar_movimiento(delta: float) -> void:
	tiempo_paso += delta
	var t = clamp(tiempo_paso / duracion_paso, 0.0, 1.0)
	position = posicion_inicio.lerp(posicion_obj, t)

	if t < 1.0:
		return

	# Finalizar paso
	position = posicion_obj
	moviendose = false
	puede_encadenar_paso = true

	# Actualizar datos guardados
	var casilla = obtener_casilla_actual()
	PlayerManager.data.grid_position = casilla
	PlayerManager.data.direction = direccion

	paso_terminado.emit()

	# Encadenar siguiente paso si se mantiene la tecla
	if puede_encadenar_paso:
		var dir = obtener_direccion_input()
		if dir != Vector2.ZERO:
			empezar_paso(dir)
			return

	mostrar_idle(direccion)


func manejar_input_quieto(delta: float) -> void:
	var dir = obtener_direccion_input()

	if dir == Vector2.ZERO:
		_resetar_input()
		mostrar_idle(direccion)
		return

	if dir != direccion:
		mirar_hacia(dir)
		_resetar_input()
		return

	if dir != direccion_input:
		direccion_input = dir
		tiempo_input = 0.0

	tiempo_input += delta
	if tiempo_input < tiempo_para_caminar:
		return

	# Intentar moverse
	if map_manager and not map_manager.puede_caminar(position, dir):
		if map_manager.has_method("es_rampa") and map_manager.es_rampa(position, dir):
			empezar_paso(dir)
			return

		if sfx_bump and not sfx_bump.playing:
			sfx_bump.play()
		tiempo_input = 0.0
	else:
		empezar_paso(dir)


func empezar_paso(dir: Vector2) -> void:
	if not map_manager:
		return

	# Escaleras
	var tipo_escalera = map_manager.obtener_tipo_escalera(position, dir) if map_manager.has_method("obtener_tipo_escalera") else ""
	if tipo_escalera in ["escalera_sube_derecha", "escalera_sube_izquierda"]:
		ejecutar_paso_escalera(dir, tipo_escalera)
		return

	# Rampas / saltos
	if map_manager.has_method("es_rampa") and map_manager.es_rampa(position, dir):
		ejecutar_salto_rampa(dir)
		return

	# Colisión normal
	if not map_manager.puede_caminar(position, dir):
		if sfx_bump and not sfx_bump.playing:
			sfx_bump.play()
		mostrar_idle(direccion)
		return

	# Movimiento normal
	direccion = dir
	_resetar_input()

	posicion_inicio = position
	posicion_obj = position + dir * tile_block
	tiempo_paso = 0.0
	moviendose = true

	reproducir_caminata(dir)


func ejecutar_salto_rampa(dir: Vector2) -> void:
	moviendose = true
	direccion = dir
	_resetar_input()
	posicion_inicio = position
	posicion_obj = position + dir * (tile_block * 2)
	tiempo_paso = 0.0

	if sfx_jump and not sfx_jump.playing:
		sfx_jump.play()

	var dur_ant = duracion_paso
	duracion_paso = 0.4
	reproducir_caminata(dir)

	# Animación de salto
	if sprite:
		var tween = create_tween().set_ease(Tween.EASE_OUT_IN)
		tween.tween_property(sprite, "position:y", -14, duracion_paso / 2)
		tween.tween_property(sprite, "position:y", 0, duracion_paso / 2)

	await paso_terminado
	duracion_paso = dur_ant


func ejecutar_paso_escalera(dir: Vector2, tipo: String) -> void:
	moviendose = true
	direccion = dir
	_resetar_input()
	posicion_inicio = position

	var dir_diag = dir
	match tipo:
		"escalera_sube_derecha":
			dir_diag = Vector2(1, -1) if dir == Vector2.RIGHT else Vector2(-1, 1)
		"escalera_sube_izquierda":
			dir_diag = Vector2(-1, -1) if dir == Vector2.LEFT else Vector2(1, 1)

	posicion_obj = position + dir_diag * tile_block
	tiempo_paso = 0.0

	# Desactivar colisiones temporalmente
	var capas_ant = collision_layer
	var masc_ant = collision_mask
	collision_layer = 0
	collision_mask = 0

	reproducir_caminata(dir)
	await paso_terminado

	collision_layer = capas_ant
	collision_mask = masc_ant


func mirar_hacia(dir: Vector2) -> void:
	direccion = dir
	mostrar_idle(dir)


func reproducir_caminata(dir: Vector2) -> void:
	var anim = _obtener_nombre_anim("walk", dir)
	if anim_player.current_animation == anim and anim_player.is_playing():
		return
	anim_player.speed_scale = velocidad_animacion
	anim_player.play(anim)


func mostrar_idle(dir: Vector2) -> void:
	var anim = _obtener_nombre_anim("walk", dir)
	if anim_player.current_animation != anim:
		anim_player.speed_scale = 1.0
		anim_player.play(anim)
	anim_player.seek(0.0, true)
	anim_player.pause()


func obtener_direccion_input() -> Vector2:
	if Input.is_action_pressed("Up"): return Vector2.UP
	if Input.is_action_pressed("Down"): return Vector2.DOWN
	if Input.is_action_pressed("Left"): return Vector2.LEFT
	if Input.is_action_pressed("Right"): return Vector2.RIGHT
	return Vector2.ZERO


func cancelar_encadenado() -> void:
	puede_encadenar_paso = false


func aplicar_datos_guardados() -> void:
	var casilla = PlayerManager.data.grid_position
	posicionar_en_casilla(casilla.x, casilla.y)
	direccion = PlayerManager.data.direction
	posicion_obj = position
	mostrar_idle(direccion)
	print("✅ Posición cargada:", casilla, " | Dirección:", direccion)


## --- Funciones auxiliares ---

func posicionar_en_casilla(x: int, y: int) -> void:
	position = Vector2(x * tile_block + 8, y * tile_block + 16)


func obtener_casilla_actual() -> Vector2i:
	var x = int(round((position.x - 8) / tile_block))
	var y = int(round((position.y - 16) / tile_block))
	return Vector2i(x, y)


func _resetar_input() -> void:
	direccion_input = Vector2.ZERO
	tiempo_input = 0.0


func _obtener_nombre_anim(tipo: String, dir: Vector2) -> String:
	return tipo + "_" + DIR_TO_ANIM[dir]


func _agregar_pokemon_prueba() -> void:
	var p = Pokemon.new()
	p.setup_new_pokemon(Species.SpeciesId.SPECIES_BULBASAUR, 10)
	if PlayerManager.data.party.is_empty():
		PlayerManager.data.party.append(p)
		print("✅ Pokémon de prueba agregado")
