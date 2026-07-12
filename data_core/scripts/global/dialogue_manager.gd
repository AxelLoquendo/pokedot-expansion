extends Node
class_name DialogoManager

signal eleccion_realizada(aceptado: bool)
var puede_interactuar: bool = true
var es_pregunta: bool = false
const RUTA_ESCENA: String = "res://scenes/menus/dialogue_box/caja_dialogo.tscn"
const RUTA_TTF: String = "res://pokemon-emerald-pro.ttf" 
const RUTA_SONIDO_AVANCE: String = "res://sfx/se/GUI sel cursor.ogg"

var caja: CanvasLayer
var fondo: Sprite2D
var texto: RichTextLabel
var indicador: Label
var sonido_avance: AudioStreamPlayer

var activo: bool = false
var en_escritura: bool = false
var velocidad: float = 0.04
var lineas: Array[String] = []
var indice_actual: int = 0
var texto_completo: String = ""
var tiempo: float = 0.0


func _ready() -> void:
	var escena = preload(RUTA_ESCENA)
	caja = escena.instantiate()
	add_child(caja)

	fondo = caja.get_node("Fondo")
	texto = caja.get_node("Texto")
	indicador = caja.get_node("Indicador")

	sonido_avance = AudioStreamPlayer.new()
	sonido_avance.stream = preload(RUTA_SONIDO_AVANCE)
	sonido_avance.volume_db = 0
	add_child(sonido_avance)

	var fuente_base = preload(RUTA_TTF)
	var fuente_variante = FontVariation.new()
	fuente_variante.base_font = fuente_base
	fuente_variante.set_spacing(TextServer.SPACING_GLYPH, 1)
	texto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	texto.add_theme_font_override("normal_font", fuente_variante)
	texto.add_theme_font_size_override("normal_font_size", 16)
	texto.add_theme_color_override("default_color", Color("636363"))
	texto.add_theme_constant_override("line_separation", 1)

	caja.visible = false
	indicador.visible = false


func mostrar(mensajes: Array[String]) -> void:
	if activo: return
	activo = true
	en_escritura = false
	es_pregunta = false
	puede_interactuar = false
	indice_actual = 0
	lineas = mensajes.duplicate()
	caja.visible = true
	indicador.visible = false
	texto.text = ""
	_mostrar_siguiente_linea()

func mostrar_pregunta(mensajes: Array[String]) -> void:
	if activo: return
	mostrar(mensajes)
	#es_pregunta = true # Marcamos que este diálogo espera un Sí o No

func _mostrar_siguiente_linea() -> void:
	if indice_actual >= lineas.size():
		_cerrar()
		return
		
	texto_completo = lineas[indice_actual]
	texto.text = ""
	tiempo = 0.0
	en_escritura = true
	indicador.visible = false
	
	# 🌟 NUEVO: Si es el último mensaje del array y venimos de "mostrar_pregunta",
	# activamos el modo pregunta RECIÉN AQUÍ.
	if indice_actual == lineas.size() - 1 and not puede_interactuar:
		es_pregunta = true
	else:
		es_pregunta = false


func _process(delta: float) -> void:
	if not activo: return

	if en_escritura:
		tiempo += delta
		var caracteres = min(int(tiempo / velocidad), texto_completo.length())
		texto.text = texto_completo.substr(0, caracteres)

		if caracteres >= texto_completo.length():
			en_escritura = false
			indicador.visible = true
	else:
		indicador.modulate.a = 0.3 + 0.7 * sin(Time.get_ticks_msec() * 0.015)


# ✅ AGREGAMOS DETECCIÓN DE ENTRADA AQUÍ
func _input(event: InputEvent) -> void:
	if not activo:
		return

	# 1. Si el evento es una pulsación (presionar un botón) procesamos nuestra lógica:
	if event.is_pressed():
		# A. Si el texto se está escribiendo, la Z salta la animación
		if en_escritura:
			if event.is_action_pressed("Interactuar"):
				get_viewport().set_input_as_handled() # 🛡️ Consumimos el input
				entrada_avanzar()
			else:
				get_viewport().set_input_as_handled() # 🛡️ Bloqueamos cualquier otra tecla mientras escribe
			return

		# B. Si ya terminó de escribir y ES PREGUNTA, evaluamos las respuestas
		if es_pregunta:
			if event.is_action_pressed("Interactuar"):
				print("🎯 [DialogueManager] Detectada confirmación SÍ (Z)")
				get_viewport().set_input_as_handled() # 🛡️ Consumimos el input
				es_pregunta = false
				eleccion_realizada.emit(true)
				_cerrar()
				return
				
			if event.is_action_pressed("Cancelar"):
				print("🎯 [DialogueManager] Detectada cancelación NO (X)")
				get_viewport().set_input_as_handled() # 🛡️ Consumimos el input
				es_pregunta = false
				eleccion_realizada.emit(false)
				_cerrar()
				return
			
			get_viewport().set_input_as_handled() # 🛡️ Bloqueamos cualquier otra tecla en la pregunta
			return

		# C. Si es un diálogo NORMAL terminado, la Z avanza de línea
		if event.is_action_pressed("Interactuar"):
			get_viewport().set_input_as_handled() # 🛡️ Consumimos el input
			entrada_avanzar()
			return

	# 2. 🚨 EL ESCUDO TOTAL: Si la caja está activa, consumimos cualquier otro tipo de entrada 
	# (teclas extras, liberaciones de botón, etc.) para que el juego de fondo esté 100% congelado.
	get_viewport().set_input_as_handled()


func entrada_avanzar() -> void:
	if not activo: return

	if sonido_avance.stream:
		sonido_avance.play()

	if en_escritura:
		texto.text = texto_completo
		en_escritura = false
		indicador.visible = true
	else:
		indice_actual += 1
		_mostrar_siguiente_linea()


func _cerrar() -> void:
	activo = false
	puede_interactuar = true
	caja.visible = false
	texto.text = ""
	indicador.visible = false
