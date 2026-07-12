extends Node2D

# ⚙️ Configuración
const TIEMPO_APARICION: float = 1.0
const TIEMPO_ESPERA: float = 2.0
const TIEMPO_DESVANECIMIENTO: float = 1.0

var _activo: bool = true
var _tween: Tween


func _ready() -> void:
	# Desactivar día/noche en la intro
	TimeManager.desactivar()

	# Empezar transparente y centrado fijo
	$Creditos.modulate.a = 0.0
	$Creditos.position = Vector2(120, 80)  # ✅ Queda fijo en el centro

	_iniciar_secuencia()


func _iniciar_secuencia() -> void:
	_tween = create_tween().set_ease(Tween.EASE_IN_OUT)

	# 1. Aparecer suavemente
	_tween.tween_property($Creditos, "modulate:a", 1.0, TIEMPO_APARICION)

	# 2. Esperar un tiempo visible
	_tween.tween_interval(TIEMPO_ESPERA)

	# ❌ QUITAMOS LA LÍNEA DE MOVER HACIA ARRIBA
	# _tween.tween_property($Creditos, "position:y", $Creditos.position.y - 30, 3.0)

	# 3. Desvanecerse
	_tween.tween_property($Creditos, "modulate:a", 0.0, TIEMPO_DESVANECIMIENTO)

	# 4. Ir a título
	_tween.tween_callback(_ir_a_titulo)


func _input(event: InputEvent) -> void:
	if not _activo: return

	if event.is_action_pressed("Abrir"):
			_ir_a_titulo()


func _ir_a_titulo() -> void:
	if not _activo: return
	_activo = false
	# ✅ Usamos la transición correcta
	TransicionManager.cambiar_escena("res://scenes/title_screen/pantalla_titulo.tscn", 0.5)
