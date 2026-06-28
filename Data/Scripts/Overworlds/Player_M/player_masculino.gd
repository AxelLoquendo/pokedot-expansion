extends CharacterBody2D

## Clase controladora del personaje jugable (Movimiento por cuadrículas estilo RPG clásico).
## Administra los inputs de dirección, estados de caminata, colisiones lógicas,
## menús de interfaz y animaciones interpoladas por baldosas.

var start_menu: Node = null # Almacena la instancia activa del menú de pausa

signal paso_terminado # Se emite al finalizar por completo el desplazamiento de una baldosa
var puede_encadenar_paso := true # Bandera que determina si el jugador puede ligar un paso con el siguiente

@export_group("Configuración de Movimiento")
@export var duracion_paso: float = 0.30 # Tiempo (en segundos) que tarda en recorrer una baldosa
@export var tile_block: int = 16 # Tamaño de la cuadrícula en píxeles
@export var velocidad_animacion: float = 0.75 # Factor de velocidad aplicado al AnimationPlayer
@export var tiempo_para_caminar: float = 0.12 # Retraso mínimo de pulsación para pasar de "mirar" a "caminar"
@export var map_manager: MapManager # Enlace al administrador de mapas para verificar físicas
# Variables de Control de Estado Interno
var moviendose := false # Verdadero si el personaje está ejecutando un desplazamiento
var posicion_inicio: Vector2 # Posición de origen antes de dar un paso
var posicion_obj: Vector2 # Posición de destino (Baldosa a la que se dirige)
var tiempo_paso := 0.0 # Cronómetro interno para la interpolación matemática (Lerp)
var direccion := Vector2.DOWN # Dirección actual hacia donde se orienta el personaje
# Manejo de Buffers de Entrada
var direccion_input := Vector2.ZERO # Último input capturado del teclado/mando
var tiempo_input := 0.0 # Tiempo acumulado con una tecla de dirección presionada

@onready var anim_player: AnimationPlayer = $AnimationPlayer # Referencia al reproductor de animaciones
# Diccionario para mapear vectores bidimensionales a sufijos de cadenas de animación
var dir_to_anim: Dictionary = {
	Vector2.UP: "up",
	Vector2.DOWN: "down",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}
#funciòn de inicio donde se define la posicion del objetivo y se iguala a la posicion para luego llamar a la funcion de mostrar idle con la variable direccion.
func _ready():
	# Inicializa los objetivos y fuerza la pose de descanso en la dirección por defecto
	posicion_obj = position
	mostrar_idle(direccion)

#funcion para manejar startmenu
func _process(_delta):
	# Captura la entrada global del menú (Tecla de confirmación / Start)
	if Input.is_action_just_pressed("ui_accept"):
		if start_menu == null:
			abrir_menu()
		else:
			cerrar_menu()
## Instancia de manera dinámica el menú de pausa en la raíz de la escena.
func abrir_menu():
	var menu_scene = preload("res://Esenas/Menus/StartMenu/startmenu.tscn")
	start_menu = menu_scene.instantiate()
	get_tree().current_scene.add_child(start_menu)
	start_menu.toggle_menu()  # <-- aquí lo activas

## Libera la memoria del menú de pausa y limpia su referencia del script.
func cerrar_menu():
	if start_menu != null:
		start_menu.queue_free()
		start_menu = null


#funcion donde se maneja la fisica en la cual se verifica si el jugador se esta moviendo, si es asi, se llama la funcion actualizar movimiento, de lo contrario llamamos la funcion que maneja la input estando quieto.
func _physics_process(delta):
	# Si el menú de pausa está interactuando, congela las físicas del personaje
	if start_menu != null and start_menu.is_open:
		mostrar_idle(direccion) # opcional
		return
	# Máquina de estados física rudimentaria dividida en movimiento y quietud
	if moviendose:
		actualizar_movimiento(delta)
	else:
		manejar_input_quieto(delta)

## Procesa la interpolación lineal (Lerp) de la posición del jugador frame a frame.
## Controla el fin del ciclo de un paso y analiza inputs encadenados.
func actualizar_movimiento(delta: float):
	tiempo_paso += delta
	# Calcula el factor de avance normalizado entre 0.0 y 1.0
	var t: float = tiempo_paso / duracion_paso
	t = clamp(t, 0.0, 1.0)
	# Mueve físicamente al personaje por el plano cartesiano
	position = posicion_inicio.lerp(posicion_obj, t)
	# Si no ha llegado al objetivo (t < 1.0), sigue procesando el Lerp en el próximo frame
	if t < 1.0:
		return
	# Forzar posición exacta al finalizar para evitar desfases numéricos de punto flotante
	position = posicion_obj
	moviendose = false
	puede_encadenar_paso = true
	# Notifica al entorno que la baldosa se completó con éxito (el MapManager revisará salidas aquí)
	paso_terminado.emit()
	# Si un factor externo (como un cambio de mapa) interrumpió el encadenamiento, frena inmediatamente
	if not puede_encadenar_paso:
		mostrar_idle(direccion)
		return
	# Revisa si el jugador mantiene teclas presionadas para encadenar el movimiento fluidamente
	var dir := obtener_direccion_input()

	if dir != Vector2.ZERO:
		empezar_paso(dir)
	else:
		mostrar_idle(direccion)
## Controla el comportamiento del personaje cuando está estático en una baldosa.
## Filtra pulsaciones cortas (para girar) de pulsaciones prolongadas (para caminar).
func manejar_input_quieto(delta: float):
	var dir := obtener_direccion_input()
	# Si no hay entrada de dirección, limpia buffers y mantiene estado Idle
	if dir == Vector2.ZERO:
		direccion_input = Vector2.ZERO
		tiempo_input = 0.0
		mostrar_idle(direccion)
		return
	# Si el input es diferente a donde mira el personaje, ejecuta un giro rápido sin desplazarse
	if dir != direccion:
		mirar_hacia(dir)
		direccion_input = dir
		tiempo_input = 0.0
		return
	# Si cambia de dirección de input repentinamente, resetea el temporizador de buffer
	if dir != direccion_input:
		direccion_input = dir
		tiempo_input = 0.0
	# Acumula el tiempo que se mantiene presionada la misma tecla
	tiempo_input += delta
	# Si supera el umbral de retención, rompe la quietud e inicia la caminata
	if tiempo_input >= tiempo_para_caminar:
		empezar_paso(dir)
## Inicializa los vectores lógicos de destino para el movimiento lineal.
## Intercepta obstrucciones para evaluar si corresponden a eventos de salto (rampas).
func empezar_paso(dir: Vector2):
	# Valida colisiones estándar a través del MapManager
	if map_manager != null and not map_manager.puede_caminar(position, dir):
		#print("¡Bloqueo detectado! Revisando si es rampa...")
		# Intercepción: Si el obstáculo es una rampa transitable, salta en lugar de frenar
		if map_manager.has_method("es_rampa"):
			var es_una_rampa = map_manager.es_rampa(position, dir)
			#print("¿El MapManager dice que es rampa?: ", es_una_rampa)
			
			if es_una_rampa:
				ejecutar_salto_rampa(dir)
				return
		#else:
			#print("ALERTA: El MapManager no tiene el método 'es_rampa'")
			
		mostrar_idle(direccion)
		return
	# Configura los parámetros para el inicio del ciclo del Lerp estándar
	direccion = dir
	direccion_input = dir
	tiempo_input = 0.0

	posicion_inicio = position
	posicion_obj = position + dir * tile_block # Avanza exactamente 1 baldosa
	tiempo_paso = 0.0
	moviendose = true

	reproducir_caminata(dir)

## Ejecuta la rutina especial de salto de repisas.
## Modifica la lógica física para avanzar 2 baldosas de golpe mientras altera
## la posición local del Sprite2D de forma parabólica para simular altura.
func ejecutar_salto_rampa(dir: Vector2):
	moviendose = true
	direccion = dir
	tiempo_input = 0.0
	
	posicion_inicio = position
	# Saltamos 2 casillas para pasar el obstáculo y caer en el suelo libre
	posicion_obj = position + dir * (tile_block * 2) # Avance lógico de 2 baldosas (cruza la rampa)
	tiempo_paso = 0.0
	
	# Ajusta la velocidad temporal del paso para dar efecto dinámico al salto
	var duracion_original = duracion_paso
	duracion_paso = 0.40 
	
	reproducir_caminata(dir)
	
	# --- ANIMACIÓN DE ARCO VISUAL (PARÁBOLA) ---
	var sprite = $Sprite2D 
	if sprite:
		var tween_arco = create_tween() 
		# Curvatura parabólica: resta Y local (sube en pantalla) y luego regresa a 0 (baja al suelo)
		tween_arco.tween_property(sprite, "position:y", -14, duracion_paso / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_arco.tween_property(sprite, "position:y", 0, duracion_paso / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Mantiene bloqueado el flujo del código hasta que el Lerp de actualizar_movimiento finalice
	await self.paso_terminado
	duracion_paso = duracion_original # Restaura el tiempo normal de caminata
## Actualiza la orientación visual del personaje sin alterar su posición por cuadrículas.
func mirar_hacia(dir: Vector2):
	direccion = dir
	mostrar_idle(dir)
## Determina y reproduce el set de animaciones de desplazamiento cíclico.
func reproducir_caminata(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation == anim_name and anim_player.is_playing():
		return

	anim_player.speed_scale = velocidad_animacion
	anim_player.play(anim_name)
## Pausa la animación en el primer frame de su ciclo para simular una postura estática.
func mostrar_idle(dir: Vector2):
	var anim_name := obtener_animacion("walk", dir)

	if anim_player.current_animation != anim_name:
		anim_player.speed_scale = 1.0
		anim_player.play(anim_name)

	anim_player.seek(0.0, true) # Salta al frame inicial
	anim_player.pause() # Congela la reproducción
## Concatena el tipo de acción y la dirección para construir el nombre del nodo de animación exacto.
func obtener_animacion(tipo: String, dir: Vector2) -> String:
	return tipo + "_" + String(dir_to_anim[dir])
## Escucha los mapeos de entrada del proyecto para retornar vectores unitarios limpios.
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
## Desactiva el flag de encadenamiento para interrumpir movimientos continuos automatizados.
func cancelar_encadenado():
	puede_encadenar_paso = false
