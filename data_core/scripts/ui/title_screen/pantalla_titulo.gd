extends Node2D

# ⚙️ Ajustes del parpadeo
const TIEMPO_PARPADEO: float = 1.2  # Velocidad del parpadeo
var _tween_parpadeo: Tween
var _activo: bool = true


func _ready() -> void:
	# Desactivar día/noche para que no afecte el menú
	TimeManager.desactivar()

	# Centrar elementos
	$Fondo.position = Vector2(120, 80)
	$TextoInicio.modulate.a = 1.0

	# Iniciar animación
	_iniciar_parpadeo()

	# Reproducir música
	$MusicaTitulo.play()


# 🔁 Parpadeo compatible con Godot 4.7
func _iniciar_parpadeo() -> void:
	if not _activo: return

	# Nueva sintaxis de Tween en 4.7
	_tween_parpadeo = create_tween()
	_tween_parpadeo.set_ease(Tween.EASE_IN_OUT)
	_tween_parpadeo.set_trans(Tween.TRANS_SINE)
	
	# ✅ En 4.7 el bucle se activa así
	_tween_parpadeo.set_loops()

	# Secuencia de la animación
	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 0.25, TIEMPO_PARPADEO)
	_tween_parpadeo.tween_property($TextoInicio, "modulate:a", 1.0, TIEMPO_PARPADEO)


# 🎮 Detectar teclas y clic
func _input(event: InputEvent) -> void:
	if not _activo: return

	if event.is_action_pressed("Abrir"):
		_empezar_juego()

# ➡️ Cambio a la escena del juego
func _empezar_juego() -> void:
	if not _activo: return
	_activo = false

	_tween_parpadeo.kill()
	$MusicaTitulo.stop()

	TransicionManager.cambiar_escena("res://scenes/menus/ui_main_menu/main_menu.tscn", 0.5)
