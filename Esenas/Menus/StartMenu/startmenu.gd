extends CanvasLayer

@onready var menu = $Control/GridContainer
var is_open = false

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
	is_open = !is_open
	visible = is_open
	
	if is_open:
		# 1. Forzamos a que el CanvasLayer actualice su visibilidad en este frame
		set_process_unhandled_input(true) 
		
		# 2. Esperamos dos frames completos para asegurarnos de que Godot pintó la interfaz
		await get_tree().process_frame
		await get_tree().process_frame
		
		# 3. Le metemos el foco al primer botón a la fuerza
		if menu.get_child_count() > 0:
			var primer_boton = menu.get_child(0)
			primer_boton.grab_focus()
			
			# Imprimimos en consola para confirmar si funcionó el asalto al foco
			print("--- CONTROL DE SEGURIDAD ---")
			print("¿Pokedex agarró el foco al abrir?: ", primer_boton.has_focus())
			
			actualizar_brillo_botones()
	else:
		# Si se cierra, apagamos la escucha de inputs de la UI
		set_process_unhandled_input(false)

# --- ACTUALIZACIÓN MANUAL DE BRILLO ---
# --- ACTUALIZACIÓN MANUAL DE SELECCIÓN (MÉTODO OPACIDAD) ---
func actualizar_brillo_botones():
	var current_focus = get_viewport().gui_get_focus_owner()
	
	for button in menu.get_children():
		if button is BaseButton:
			if button == current_focus:
				# BOTÓN SELECCIONADO: Lo hacemos brillar bastante (Color custom o alta exposición)
				# Si quieres que se vuelva azul/celeste estilo GBA, usa Color(1.0, 1.8, 2.0)
				button.self_modulate = Color(1.703, 1.752, 1.8, 0.863) 
			else:
				# BOTÓN NORMAL: Color original sin alteraciones
				button.self_modulate = Color(1.0, 1.0, 1.0, 0.902)

# --- CONTROL MANUAL DE DESPLAZAMIENTO ---
func _unhandled_input(event):
	if not is_open:
		return
		
	# 1. ¿Quién tiene el foco real en Godot?
	var current_focus = get_viewport().gui_get_focus_owner()
	print("--- INTENTO DE MOVIMIENTO ---")
	print("Nodo con foco actual: ", current_focus)
	
	if current_focus == null:
		print("ERROR: ¡Nadie tiene el foco! Se perdió.")
		return
		
	if not current_focus.get_parent() == menu:
		print("ERROR: El nodo enfocado no es hijo de GridContainer. Su padre es: ", current_focus.get_parent().name)
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
			
	print("Índice actual: ", current_index, " -> Intento de nuevo índice: ", new_index)
			
	if new_index != current_index:
		menu.get_child(new_index).grab_focus()
		print("¡Foco cambiado con éxito al nodo: ", menu.get_child(new_index).name, "!")
		actualizar_brillo_botones()
		get_viewport().set_input_as_handled()

func _on_option_selected(option: String):
	match option:
		"Pokedex": print("Abrir Pokédex")
		"Pokemon": print("Abrir equipo Pokémon")
		"Mochila": print("Abrir mochila")
		"Perfil": print("Mostrar tarjeta de entrenador")
		"Salvar": print("Guardar partida")
		"Opciones": print("Abrir opciones")
