extends RefCounted
class_name PlayerData

const MAX_PARTY = 6

# 🔹 Datos básicos del jugador
@export var player_name: String = ""
@export var money: int = 0
@export var play_time: float = 0.0
@export var ranura_guardada: int = -1

# 🔹 Posición y ubicación en el mundo
@export var current_map_scene: String = "" # La que ya tenías
@export var current_map_section: MapSections.SectionID = MapSections.SectionID.MAPSEC_NONE
@export var grid_position: Vector2i = Vector2i(7, 11)
@export var direction: Vector2 = Vector2.DOWN

# 🔹 Progreso del juego
@export var badges: Array = []
@export var flags: Dictionary = {}
@export var items: Dictionary = {}
@export var key_items: Array = []
@export var party: Array = []

# 🔹 Configuración de opciones
@export var music_volume: float = 1.0
@export var sfx_volume: float = 1.0
@export var text_speed: float = 0.05
