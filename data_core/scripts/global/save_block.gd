extends Node
class_name SaveManager

const SAVE_FOLDER = "user://saves/"
const SAVE_EXT = ".save"
const SAVE_VERSION = "1.0"

# Ranura que el jugador tiene seleccionada en el menú
var ranura_seleccionada_menu: int = -1
# Ranura activa durante la partida
var ranura_activa: int = -1


func _ready() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("saves"):
			dir.make_dir("saves")
			print("✅ Carpeta de guardados creada correctamente")
	else:
		push_error("❌ No se pudo acceder a la carpeta de usuario")


# --- NUEVA: Marcar ranura al navegar en el menú ---
func seleccionar_ranura_en_menu(ranura: int) -> void:
	if ranura >= 1 and ranura <= 3:
		ranura_seleccionada_menu = ranura
		print("📌 Ranura seleccionada en menú: ", ranura_seleccionada_menu)


func ranura_existe(ranura: int) -> bool:
	if ranura < 1 or ranura > 3:
		return false
	return FileAccess.file_exists(SAVE_FOLDER + "ranura_" + str(ranura) + SAVE_EXT)


# --- MODIFICACIÓN EN PARTIDA NUEVA ---
func iniciar_partida_nueva(ranura_destino: int = -1) -> void:
	PlayerManager.viene_de_continuar = false # 🌟 Garantiza que es partida nueva
	if ranura_destino == -1:
		if ranura_seleccionada_menu != -1:
			ranura_destino = ranura_seleccionada_menu
			print("🆕 Usando ranura seleccionada en menú: ", ranura_destino)
		else:
			ranura_destino = 1
			print("🆕 Sin ranura seleccionada, usamos la 1 por defecto")

	if ranura_destino < 1 or ranura_destino > 3:
		DialogueManager.mostrar(["❌ Ranura inválida"])
		return

	# Si ya existen datos, advertimos que al guardar se va a reescribir esta ranura
	if ranura_existe(ranura_destino):
		DialogueManager.mostrar_pregunta([
			"⚠️ La ranura " + str(ranura_destino) + " ya tiene datos.",
			"¿Estás seguro de iniciar una nueva partida aquí?\n(Se sobrescribirá al guardar)\nSí = Z | No = X"
		])
		
		var aceptar: bool = await esperar_eleccion()
		
		while DialogueManager.activo:
			DialogueManager._cerrar()
			await get_tree().process_frame
			
		if not aceptar:
			print("❌ Operación cancelada por el usuario.")
			ranura_activa = -1 # 🌟 Aseguramos que vuelva a -1 si cancela
			return

	# 🌟 Inicializamos los datos a través del PlayerManager pasándole la ranura
	PlayerManager.new_game("Jugador", ranura_destino)

	# Sincronizamos el estado local de este SaveManager
	ranura_activa = ranura_destino
	ranura_seleccionada_menu = ranura_destino

	print("📌 Nueva partida preparada en RAM. Ranura destino preasignada: ", ranura_destino)

	# Preparar y cargar escena del mapa inicial
	var map_manager = get_tree().get_first_node_in_group("MapManager")
	if map_manager and is_instance_valid(map_manager):
		PlayerManager.data.current_map_scene = "res://mapas/mapa_inicial.tres"
		PlayerManager.data.grid_position = Vector2i(5, 5)
		map_manager.current_map = PlayerManager.data.current_map_scene
		map_manager.posicion_inicial = PlayerManager.data.grid_position
		map_manager.cargar_mapa_inicial()


# --- MODIFICACIÓN EN GUARDAR PARTIDA (CORREGIDO PARA TECLA G) ---
func guardar_partida(ranura: int = -1) -> void:
	print("💾 [SaveManager] Intentando guardar. Diagnóstico de RAM:")
	print("   -> Parámetro entrante 'ranura': ", ranura)
	print("   -> ranura_activa local: ", ranura_activa)
	print("   -> ranura_seleccionada_menu: ", ranura_seleccionada_menu)
	if PlayerManager and PlayerManager.data:
		print("   -> PlayerManager.data.ranura_guardada: ", PlayerManager.data.ranura_guardada)

	# 🌟 Cadena de rescate estricta para la tecla G:
	if ranura == -1:
		if PlayerManager and PlayerManager.data and PlayerManager.data.ranura_guardada > 0:
			ranura = PlayerManager.data.ranura_guardada
			print("   🎯 Rescate exitoso desde PlayerManager.data: ", ranura)
		elif ranura_activa > 0:
			ranura = ranura_activa
			print("   🎯 Rescate exitoso desde ranura_activa local: ", ranura)
		elif ranura_seleccionada_menu > 0:
			ranura = ranura_seleccionada_menu
			print("   🎯 Rescate de emergencia desde la selección del menú: ", ranura)
		else:
			ranura = 1
			print("   🚨 Fallo total de rastreo. Forzando ranura 1 por defecto.")

	# Sincronizamos todas las variables con la ranura definitiva obtenida
	ranura_activa = ranura
	if PlayerManager and PlayerManager.data:
		PlayerManager.data.ranura_guardada = ranura

	if ranura < 1 or ranura > 3:
		DialogueManager.mostrar(["❌ Ranura inválida"])
		return

	if not ranura_existe(ranura):
		print("ℹ️ Ranura vacía, guardando directo por primera vez en la ranura: ", ranura)
		_ejecutar_guardado(ranura)
		return

	print("🔍 Confirmando guardado sobre ranura: ", ranura)
	DialogueManager.mostrar_pregunta([
		"¿Quieres sobrescribir los datos de la ranura " + str(ranura) + "?\nSí = Z | No = X"
	])

	var aceptar_guardado: bool = await esperar_eleccion() 

	while DialogueManager.activo:
		DialogueManager._cerrar()
		await get_tree().process_frame

	if aceptar_guardado:
		print("✅ Sobrescribiendo ranura: ", ranura)
		_ejecutar_guardado(ranura)
	else:
		print("❌ Guardado cancelado")


# --- MODIFICACIÓN EN CARGAR PARTIDA ---
func cargar_partida(ranura: int = -1) -> bool:
	if ranura == -1:
		ranura = ranura_seleccionada_menu
		if ranura == -1:
			DialogueManager.mostrar(["❌ Selecciona una ranura primero"])
			return false

	if ranura < 1 or ranura > 3:
		DialogueManager.mostrar(["❌ Ranura inválida"])
		return false

	var ruta = SAVE_FOLDER + "ranura_" + str(ranura) + SAVE_EXT
	if not FileAccess.file_exists(ruta):
		DialogueManager.mostrar(["⚠️ No hay partida en esta ranura"])
		return false

	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if not archivo:
		DialogueManager.mostrar(["❌ No se pudo abrir el archivo"])
		return false

	var contenido = archivo.get_as_text()
	archivo.close()

	var datos = JSON.parse_string(contenido)
	if not datos or not datos is Dictionary:
		DialogueManager.mostrar(["❌ Archivo dañado"])
		return false

	var j = datos.get("jugador", {})

	# Carga normal a memoria RAM del PlayerManager
	PlayerManager.data.player_name = j.get("nombre", "")
	PlayerManager.data.money = j.get("dinero", 0)
	PlayerManager.data.play_time = j.get("tiempo_jugado", 0.0)
	PlayerManager.data.grid_position = Vector2i(j.get("pos_x", 0), j.get("pos_y", 0))
	PlayerManager.data.direction = Vector2(j.get("dir_x", 0), j.get("dir_y", 1))
	PlayerManager.data.badges = Array(j.get("medallas", []))
	PlayerManager.data.flags = j.get("banderas", {})
	PlayerManager.data.items = j.get("objetos", {})
	PlayerManager.data.key_items = Array(j.get("objetos_clave", []))
	PlayerManager.data.music_volume = j.get("volumen_musica", 1.0)
	PlayerManager.data.sfx_volume = j.get("volumen_efectos", 1.0)
	PlayerManager.data.text_speed = j.get("velocidad_texto", 0.05)
	PlayerManager.data.current_map_scene = j.get("mapa", "")
	PlayerManager.data.ranura_guardada = j.get("ranura_guardada", ranura)
	
	PlayerManager.data.party = _deserializar_equipo(datos.get("equipo", []))

	# 🌟 LEER LA RANURA GUARDADA DESDE EL ARCHIVO SI EXISTE
	var ranura_leida_json = j.get("ranura_guardada", ranura)

	# Sincronizamos las tres variables
	ranura_activa = ranura_leida_json
	ranura_seleccionada_menu = ranura_leida_json
	if "ranura_guardada" in PlayerManager.data:
		PlayerManager.data.ranura_guardada = ranura_leida_json

	print("✅ Carga completa. Ranura activa anclada en PlayerManager: ", ranura_activa)
	PlayerManager.viene_de_continuar = true 
	return true


# --- SISTEMAS DE ENTRADA Y OPERACIONES ---
func esperar_eleccion() -> bool:
	var espera = 4
	while espera > 0:
		await get_tree().process_frame
		espera -= 1

	Input.flush_buffered_events()

	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("Interactuar"):
			return true
		if Input.is_action_just_pressed("Cancelar"):
			return false
	return false


func _ejecutar_guardado(ranura: int) -> void:
	if not PlayerManager:
		push_error("PlayerManager no disponible")
		return

	var jugador = get_tree().get_first_node_in_group("jugador")
	var map_manager = get_tree().get_first_node_in_group("MapManager")
	if jugador and map_manager:
		PlayerManager.data.grid_position = map_manager.posicion_a_tile(jugador.position)
		PlayerManager.data.direction = jugador.direccion
		PlayerManager.data.current_map_scene = map_manager.current_map.scene_file_path

	var datos_jugador = {
		"ranura_guardada": PlayerManager.data.ranura_guardada,  # ✅ GUARDAMOS LA RANURA EN EL ARCHIVO
		"nombre": PlayerManager.data.player_name,
		"dinero": PlayerManager.data.money,
		"tiempo_jugado": PlayerManager.data.play_time,
		"pos_x": PlayerManager.data.grid_position.x,
		"pos_y": PlayerManager.data.grid_position.y,
		"dir_x": PlayerManager.data.direction.x,
		"dir_y": PlayerManager.data.direction.y,
		"mapa": PlayerManager.data.current_map_scene,
		"medallas": PlayerManager.data.badges,
		"banderas": PlayerManager.data.flags,
		"objetos": PlayerManager.data.items,
		"objetos_clave": PlayerManager.data.key_items,
		"volumen_musica": PlayerManager.data.music_volume,
		"volumen_efectos": PlayerManager.data.sfx_volume,
		"velocidad_texto": PlayerManager.data.text_speed
	}

	var guardado = {
		"version": SAVE_VERSION,
		"fecha": Time.get_datetime_string_from_system(),
		"jugador": datos_jugador,
		"equipo": _serializar_equipo(PlayerManager.data.party)
	}

	var ruta = SAVE_FOLDER + "ranura_" + str(ranura) + SAVE_EXT

	if FileAccess.file_exists(ruta):
		var dir = DirAccess.open(SAVE_FOLDER)
		if dir:
			dir.remove("ranura_" + str(ranura) + SAVE_EXT)

	var archivo = FileAccess.open(ruta, FileAccess.WRITE)
	if not archivo:
		push_error("❌ Falló apertura del archivo")
		return

	archivo.store_string(JSON.stringify(guardado, "\t"))
	archivo.close()

	print("✅ Datos guardados en ranura: ", ranura)
	DialogueManager.mostrar(["✅ Partida guardada en ranura " + str(ranura)])


func buscar_ranura_libre() -> int:
	for i in range(1, 4):
		if not ranura_existe(i):
			return i
	return -1


func aplicar_posicion_al_jugador() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	var map_manager = get_tree().get_first_node_in_group("MapManager")
	if jugador and map_manager:
		jugador.position = map_manager.tile_a_posicion(PlayerManager.data.grid_position)
		jugador.direccion = map_manager.PlayerManager.data.direction
		print("✅ Posición aplicada")


func _serializar_equipo(equipo: Array) -> Array:
	var lista: Array = []
	for poke in equipo:
		if not poke or not is_instance_valid(poke):
			continue
		lista.append({
			"especie": int(poke.species_id),
			"nivel": poke.level,
			"exp": poke.experience,
			"ps": poke.current_hp,
			"ps_max": poke.max_hp,
			"estado": int(poke.status_condition),
			"iv": [poke.iv_hp, poke.iv_attack, poke.iv_defense, poke.iv_speed, poke.iv_sp_attack, poke.iv_sp_defense],
			"ev": [poke.ev_hp, poke.ev_attack, poke.ev_defense, poke.ev_speed, poke.ev_sp_attack, poke.ev_sp_defense],
			"naturaleza": int(poke.nature),
			"apodo": poke.nickname,
			"sexo": int(poke.gender),
			"movs": poke.moves.map(func(m): return int(m))
		})
	return lista


func _deserializar_equipo(lista: Array) -> Array:
	var equipo: Array = []
	if not lista or lista.is_empty():
		return equipo

	for d in lista:
		var p = Pokemon.new()
		p.species_id = int(d.get("especie", 0))
		p.level = int(d.get("nivel", 1))
		p.experience = int(d.get("exp", 0))
		p.current_hp = int(d.get("ps", 0))
		p.max_hp = int(d.get("ps_max", p.get_max_hp()))
		p.status_condition = int(d.get("estado", 0))

		var iv = d.get("iv", [0,0,0,0,0,0])
		p.iv_hp = int(iv[0])
		p.iv_attack = int(iv[1])
		p.iv_defense = int(iv[2])
		p.iv_speed = int(iv[3])
		p.iv_sp_attack = int(iv[4])
		p.iv_sp_defense = int(iv[5])

		var ev = d.get("ev", [0,0,0,0,0,0])
		p.ev_hp = int(ev[0])
		p.ev_attack = int(ev[1])
		p.ev_defense = int(ev[2])
		p.ev_speed = int(ev[3])
		p.ev_sp_attack = int(ev[4])
		p.ev_sp_defense = int(ev[5])

		p.nature = int(d.get("naturaleza", 0))
		p.nickname = str(d.get("apodo", ""))
		p.gender = int(d.get("sexo", 0))

		p.moves.clear()
		for move_id in d.get("movs", []):
			p.moves.append(int(move_id))

		p.current_hp = clamp(p.current_hp, 0, p.max_hp)
		equipo.append(p)

	return equipo
