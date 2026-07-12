extends Node2D
class_name MainMenu

# ⚙️ Configuración
const RANURAS_TOTALES = 3
const ESCENA_OVERWORLD = "res://data_core/maps/overworld_base/overworld.tscn" # Pon tu ruta real

# 🔗 Referencias a nodos
@onready var btn_continue: TextureButton = $Continue
@onready var btn_new_game: TextureButton = $New_Game
@onready var btn_option: TextureButton = $Option

@onready var lbl_mapa: Label = $Continue/Mapa
@onready var lbl_tiempo: Label = $Continue/Tiempo
@onready var lbl_nombre: Label = $Continue/Nombre
@onready var lbl_dex: Label = $Continue/Pokedex
@onready var lbl_medallas: Label = $Continue/Medallas

# 🔊 Sonidos
@onready var sfx_mover: AudioStreamPlayer = $SFX_Mover
@onready var sfx_aceptar: AudioStreamPlayer = $SFX_Aceptar

# 🧠 Estado interno
var indice_foco: int = 0 # 0 = Continue, 1 = New Game, 2 = Options
var ranura_actual: int = 1 # Ranura seleccionada solo en Continue


func _ready() -> void:
	actualizar_foco_visual()
	actualizar_info_ranura()
	# ✅ Al iniciar, marcamos la ranura por defecto
	SaveBlock.seleccionar_ranura_en_menu(ranura_actual)


# 🎮 Entradas CORREGIDAS
func _input(event: InputEvent) -> void:
	if not event is InputEventKey and not event is InputEventAction:
		return
	if not event.pressed:
		return

	if Input.is_action_just_pressed("Up"):
		navegar(-1)
	elif Input.is_action_just_pressed("Down"):
		navegar(1)

	elif Input.is_action_just_pressed("Left"):
		if indice_foco == 0:
			# En "Continuar" → cambiamos ranura
			cambiar_ranura(-1)
		else:
			# En "Nueva Partida" u "Opciones" → cambiamos opción
			navegar(-1)

	elif Input.is_action_just_pressed("Right"):
		if indice_foco == 0:
			# En "Continuar" → cambiamos ranura
			cambiar_ranura(1)
		else:
			# En "Nueva Partida" u "Opciones" → cambiamos opción
			navegar(1)

	elif Input.is_action_just_pressed("Interactuar"):
		ejecutar_accion()


# 🧭 Cambiar opción seleccionada
func navegar(paso: int) -> void:
	indice_foco = clamp(indice_foco + paso, 0, 2)
	sfx_mover.play()
	actualizar_foco_visual()
	actualizar_info_ranura()


# 🎚️ Cambiar ranura de guardado
func cambiar_ranura(paso: int) -> void:
	ranura_actual = clamp(ranura_actual + paso, 1, RANURAS_TOTALES)
	sfx_mover.play()
	SaveBlock.seleccionar_ranura_en_menu(ranura_actual)
	actualizar_info_ranura()


# ✨ Efecto de brillo
func actualizar_foco_visual() -> void:
	btn_continue.modulate = Color(0.6, 0.6, 0.6)
	btn_new_game.modulate = Color(0.6, 0.6, 0.6)
	btn_option.modulate = Color(0.6, 0.6, 0.6)

	match indice_foco:
		0: btn_continue.modulate = Color(1, 1, 1)
		1: btn_new_game.modulate = Color(1, 1, 1)
		2: btn_option.modulate = Color(1, 1, 1)


# 📂 Mostrar información de la ranura
func actualizar_info_ranura() -> void:
	if indice_foco != 0:
		lbl_mapa.text = ""
		lbl_tiempo.text = ""
		lbl_nombre.text = ""
		lbl_dex.text = ""
		lbl_medallas.text = ""
		return

	if not SaveBlock.ranura_existe(ranura_actual):
		lbl_mapa.text = "Ranura vacía"
		lbl_tiempo.text = "--:--:--"
		lbl_nombre.text = "---"
		lbl_dex.text = "---"
		lbl_medallas.text = "---"
		return

	var ruta = SaveBlock.SAVE_FOLDER + "ranura_" + str(ranura_actual) + SaveBlock.SAVE_EXT
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if not archivo:
		lbl_mapa.text = "Error al leer"
		return

	var datos = JSON.parse_string(archivo.get_as_text())
	archivo.close()

	if not datos or not datos is Dictionary:
		lbl_mapa.text = "Archivo dañado"
		return

	var j = datos.get("jugador", {})

	var tiempo_total = int(j.get("tiempo_jugado", 0.0))
	var horas = tiempo_total / 3600
	var minutos = (tiempo_total % 3600) / 60
	var segundos = tiempo_total % 60

	var ruta_mapa = j.get("mapa", "")
	lbl_mapa.text = ruta_mapa.get_file().get_basename().replace("_", " ").capitalize() if not ruta_mapa.is_empty() else "Sin mapa"
	lbl_tiempo.text = "%02d:%02d:%02d" % [horas, minutos, segundos]
	lbl_nombre.text = j.get("nombre", "Sin nombre") # ✅ Corregí aquí: antes decía "Nombre" con mayúscula
	lbl_dex.text = "Dex " + str(j.get("pokedex", 0)) # ✅ También aquí
	lbl_medallas.text = "Badges " + str(j.get("medallas", []).size())


# ⚡ Ejecutar acción
func ejecutar_accion() -> void:
	sfx_aceptar.play()

	match indice_foco:
		0: # Cargar partida
			if not SaveBlock.ranura_existe(ranura_actual):
				return
			# ✅ Usamos la función actualizada del SaveBlock
			SaveBlock.cargar_partida(ranura_actual)
			TransicionManager.cambiar_escena(ESCENA_OVERWORLD, 0.5)

		1: # ✅ NUEVA PARTIDA
			# Ejecutamos la función asíncrona y esperamos a que el flujo termine por completo
			await SaveBlock.iniciar_partida_nueva()
			
			# 🌟 CONTROL DE SEGURIDAD: 
			# Si el usuario seleccionó "No" (X), la ranura_activa del SaveBlock se quedará en -1 o no se habrá fijado.
			# Solo cambiamos de escena si el flujo terminó en una ranura válida asignada.
			if SaveBlock.ranura_activa != -1:
				TransicionManager.cambiar_escena(ESCENA_OVERWORLD, 0.5)
			else:
				print("🔄 Permaneciendo en el menú principal: El jugador canceló la sobreescritura.")

		2: # Opciones
			print("Abrir menú de opciones")
