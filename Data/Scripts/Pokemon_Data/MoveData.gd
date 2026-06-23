extends Resource

class_name MoveData

@export_group("Información Base")
@export var move_id: Moves.MoveId
@export var move_name: String
@export_multiline var description: String
@export var type: PokemonData.Type
@export var category: MoveStruct.DamageCategory
@export var target: MoveStruct.MoveTarget

@export_group("Parámetros Numéricos")
@export var power: int
@export var accuracy: int
@export var pp: int
@export var priority: int = 0
@export var crit_stage: int = 0
@export var min_hits: int = 1
@export var max_hits: int = 1
@export var drain_percent: int = 0
@export var recoil_percent: int = 0

@export_group("Flags Mecánicas de Combate")
@export var is_multi_hit := false   # C: multiHit (Prioriza la lógica de golpes múltiples)
@export var is_explosion := false   # C: explosion (Lógica especial de autodestrucción y modificador de daño)

@export_group("Efectos")
@export var effect: MoveStruct.MoveEffect
@export var secondary_effect: MoveStruct.SecondaryEffect
@export var secondary_chance: int = 0

@export_group("Flags de Tipo de Movimiento")
@export var makes_contact := false
@export var punching_move := false
@export var biting_move := false
@export var slicing_move := false
@export var sound_move := false
@export var ballistic_move := false  # Antibalas
@export var pulse_move := false      # Megadisparador
@export var powder_move := false     # Inmunidad Planta/Gafas Protectoras
@export var wind_move := false       # Surcavientos
@export var dance_move := false      # Habilidad Danzarina
@export var healing_move := false    # Anticura

@export_group("Flags de Interacción Extensas")
@export var magic_coat_affected := false  # Reflejable por Capa Mágica/Espejo Mágico
@export var snatch_affected := false      # Robable por Robo (Snatch)
@export var ignores_kings_rock := false   # No activa Roca del Rey
@export var thaws_user := false           # Descongela al usuario al usarlo (Ataques Fuego)
@export var force_pressure := false       # Consume PP extra por Presión obligatoriamente
@export var cant_use_twice := false       # Movimientos de recarga/no consecutivos

@export_group("Flags de Precisión y Evasión")
@export var always_hits := false
@export var ignores_protect := false
@export var ignores_substitute := false
@export var always_critical := false
@export var ignores_target_ability := false # Efecto Rompemoldes integrado
@export var ignores_target_defense_evasion_stages := false

@export_group("Flags de Clima")
@export var always_hits_in_rain := false
@export var always_hits_in_hail_snow := false
@export var accuracy_50_in_sun := false

@export_group("Flags de Estados Especiales del Rival")
@export var minimize_double_damage := false # Doble daño si el rival usó Reducción
@export var damages_underground := false     # Golpea bajo tierra (Terremoto vs Excavar)
@export var damages_underwater := false      # Golpea bajo el agua (Surf vs Bucear)
@export var damages_airborne := false        # Golpea en el aire (Tornado vs Vuelo)
@export var damages_airborne_double_damage := false

@export_group("Baneos")
# --- Ban Flags (Total parity with Pokeemerald Expansion) ---
@export var gravity_banned := false        
@export var mirror_move_banned := false    
@export var me_first_banned := false       
@export var mimic_banned := false          
@export var metronome_banned := false      
@export var copycat_banned := false        
@export var assist_banned := false         
@export var sleep_talk_banned := false     
@export var instruct_banned := false       
@export var encore_banned := false         
@export var parental_bond_banned := false  
@export var sky_battle_banned := false     
@export var sketch_banned := false         
@export var damp_banned := false
