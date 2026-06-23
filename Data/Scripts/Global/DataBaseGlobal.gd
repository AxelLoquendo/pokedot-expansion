extends Node

var abilities: Dictionary = {}
var items: Dictionary = {}
var moves: Dictionary = {}
var pokemons: Dictionary = {}

func _ready() -> void:
	print("Cargando recursos")
	_load_database("res://Data/Ability/", abilities, "ability_id")
	_load_database("res://Data/Pokemon/", pokemons, "species_id")
	_load_database("res://Data/Move/", moves, "move_id")
	print("recursos cargados")

func _load_database(folder_path: String, target_dictionary: Dictionary, id_variable_name: String) -> void:
	var dir = DirAccess.open(folder_path)
	
	if not dir:
		push_warning("[Database Error] No se pudo abrir la carpeta: " + folder_path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				var subfolder_path = folder_path + file_name + "/"
				_load_database(subfolder_path, target_dictionary, id_variable_name)
		
		elif file_name.ends_with(".tres"):
			var resource = load(folder_path + file_name)
			
			if resource:
				if id_variable_name in resource:
					var resource_id = resource.get(id_variable_name)
					
					# Control de duplicados por seguridad
					if target_dictionary.has(resource_id):
						push_error("[Database CRITICAL] ¡ID DUPLICADO! '%s' ya existe en '%s'. Archivo en conflicto: '%s'" % [resource_id, target_dictionary[resource_id].resource_path.get_file(), file_name])
					
					target_dictionary[resource_id] = resource
				else:
					push_error("[Database Error] El archivo '%s' no tiene la propiedad '%s'." % [file_name, id_variable_name])
					
		file_name = dir.get_next()
	dir.list_dir_end()
	print("-> Carga completa: %d elementos indexados desde '%s'" % [target_dictionary.size(), folder_path])
