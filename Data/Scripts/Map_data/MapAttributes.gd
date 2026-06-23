extends Resource

class_name MapAttributes

@export_category("Identity")
@export var map_id: int
@export var map_name: String
@export var map_section_id: MapSections.SectionID
@export var map_size: Vector2i = Vector2i(20, 15)
@export var is_indoor := false
@export var allow_escape_rope := false
@export var allow_fly := false
@export var region_id: MapSections.RegionId

@export var north_map: MapConnection
@export var east_map: MapConnection
@export var south_map: MapConnection
@export var west_map: MapConnection

@export_category("Audio & Visuals")
# Guarda el path al archivo de música para no saturar la memoria cargando el audio directo
@export_file("*.ogg", "*.wav", "*.mp3") var music_path: String
#@export var weather: PokemonData.Weather = PokemonData.Weather.NONE
#@export var battle_background: MapStruct.BattleBg = MapStruct.BattleBg.GRASS

@export_category("Wild Encounters")
# Un recurso limpio que crearemos luego para contener las listas de hierba, agua, pesca, etc.
#@export var encounter_data: MapEncountersData
