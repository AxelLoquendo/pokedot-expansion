extends CanvasLayer

const RUTA_PARTY_MENU: String = "res://scenes/menus/party_menu/party_menu.tscn"
const PARTY_MENU: PackedScene = preload(RUTA_PARTY_MENU)

@onready var menu = $Control/GridContainer
@onready var sfx_tilegamecursor: AudioStreamPlayer = $TileGameCursor # Referencia de sonido
@onready var sfx_uimenuopen: AudioStreamPlayer = $UImenuOpen
@onready var sfx_uimenuclose: AudioStreamPlayer = $UImenuClose

var is_open = false
var puede_cerrarse := false # <-- NUEVA BANDERA: Escudo antibugs para el input

func _ready():
	visible = false
	
	for button in menu.get_children():
		if button is BaseButton:
			button.focus_mode = Control.FOCUS_ALL
			# Ponemos todos los botones en su brillo normal al iniciar
			button.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			if not button.is_connected("pressed", Callable(self, "_on_option_selected").bind(button.name)):
				button.connect("pressed", Callable(self, "_on_option_selected").bind(button.name))

func toggle_menu():
	# Si el jugador intenta cerrarlo inmediatamente por el rebote de la tecla, lo frenamos en seco
	if is_open and not puede_cerrarse:
		return

	is_open = !is_open
	visible = is_open
	
	if is_open:
		puede_cerrarse = false # Bloqueamos el cierre inmediato
		
		# ¡SONIDO DE APERTURA!
		if sfx_uimenuopen:
			sfx_uimenuopen.play()

		# 1. Forzamos a que el CanvasLayer actualice su visibilidad en este frame
		set_process_unhandled_input(true) 
		
		# Consumimos el input de este frame para mitigar el rebote
		get_viewport().set_input_as_handled()
		
		# 2. Esperamos dos frames completos para que Godot pinte la interfaz y pase el peligro del rebote
		await get_tree().process_frame
		await get_tree().process_frame
		
		# 3. Le metemos el foco al primer botón a la fuerza
		if is_inside_tree() and menu.get_child_count() > 0:
			var primer_boton = menu.get_child(0)
			primer_boton.grab_focus()
			
			# Imprimimos en consola para confirmar si funcionó el asalto al foco
			print("--- CONTROL DE SEGURIDAD ---")
			print("¿Pokedex agarró el foco al abrir?: ", primer_boton.has_focus())
			
			actualizar_brillo_botones()
		
		# Una vez que el foco está puesto y pasaron los frames críticos, activamos el escudo
		puede_cerrarse = true
	else:
		# ¡SONIDO DE CIERRE!
		if sfx_uimenuclose:
			sfx_uimenuclose.play()
			# Esperamos a que el sonido termine de reproducirse 
			# antes de que el script del jugador ejecute el queue_free()
			await sfx_uimenuclose.finished

		# Si se cierra, apagamos la escucha de inputs de la UI
		set_process_unhandled_input(false)

# --- ACTUALIZACIÓN MANUAL DE BRILLO (CORREGIDO) ---
func actualizar_brillo_botones():
	# ESCUDO: Si el menú está saliendo de la memoria, frenamos la ejecución
	if not is_inside_tree():
		return
		
	var vp = get_viewport()
	if vp == null:
		return
		
	var current_focus = vp.gui_get_focus_owner()
	
	for button in menu.get_children():
		if button is BaseButton:
			if button == current_focus:
				button.self_modulate = Color(1.703, 1.752, 1.8, 0.863) 
			else:
				button.self_modulate = Color(1.0, 1.0, 1.0, 0.902)

# --- CONTROL MANUAL DE DESPLAZAMIENTO ---
func _unhandled_input(event):
	if DialogueManager and DialogueManager.activo:
		return
	if not is_open:
		return
		
	var vp = get_viewport()
	if vp == null:
		return
		
	var current_focus = vp.gui_get_focus_owner()
	
	if current_focus == null or not current_focus.get_parent() == menu:
		return
		
	var current_index = current_focus.get_index()
	var new_index = current_index
	
	if event.is_action_pressed("Right"):
		if current_index % 2 == 0 and current_index + 1 < menu.get_child_count():
			new_index = current_index + 1
	elif event.is_action_pressed("Left"):
		if current_index % 2 != 0:
			new_index = current_index - 1
	elif event.is_action_pressed("Down"):
		if current_index + 2 < menu.get_child_count():
			new_index = current_index + 2
	elif event.is_action_pressed("Up"):
		if current_index - 2 >= 0:
			new_index = current_index - 2
			
	if new_index != current_index and is_inside_tree():
		menu.get_child(new_index).grab_focus()
		
		# ¡REPRODUCIR SONIDO DE DESPLAZAMIENTO!
		if sfx_tilegamecursor:
			sfx_tilegamecursor.play()
			
		actualizar_brillo_botones()
		get_viewport().set_input_as_handled()

func _on_option_selected(option: String):
	# ESCUDO: Asegurar que el nodo existe antes de procesar la selección
	if not is_inside_tree():
		return

	match option:
		"Pokemon": 
			if PlayerManager.data.party.is_empty():
				print("No tienes Pokémon en el equipo.") 
				return
				
			print("✅ Abriendo menú de equipo")
			
			var party_menu = PARTY_MENU.instantiate()
			get_parent().add_child(party_menu)
			
			set_process_unhandled_input(false)
			self.hide()
			
			# Esperamos que el Party Menu se cierre
			await party_menu.tree_exited
			
			# ESCUDO POST-AWAIT: Si el juego se cerró estando en el Party Menu, frenamos aquí
			if not is_inside_tree():
				return
				
			self.show()
			set_process_unhandled_input(true)
			
			# Devolvemos el foco al botón de manera segura
			var boton_pokemon = menu.get_node_or_null("Pokemon")
			if boton_pokemon:
				boton_pokemon.grab_focus()
				
			actualizar_brillo_botones()
			
		"Pokedex":
			print("Abriendo Pokedex... (Próximamente)")
		"Mochila":
			print("Abriendo Mochila... (Próximamente)")

func _on_opcion_pokemon_pressed():
	if PlayerManager.data.party.is_empty():
		print("No tienes Pokémon en el equipo.") 
		return
		
	var party_menu_scene = load("res://scenes/Menus/PartyMenu/PartyMenu.tscn") 
	var party_menu = party_menu_scene.instantiate()
	
	get_parent().add_child(party_menu)
	self.hide()
	
	await party_menu.tree_exited
	if is_inside_tree():
		self.show()
