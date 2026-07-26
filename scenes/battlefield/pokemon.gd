class_name Pokemon
extends RefCounted

## String con info extraíble de mensajes textuales: side, nickname.
## Vacío entre el Team Preview y el primer switch-in.
## Ejemplos: "p1: Unown" o "p2: Sparky"
var ident: String = ""

## Especie/forma del Pokémon
var species_forme: String = ""

## String con info visible no incluida en ident: especie, nivel, género, shiny.
## El nivel se omite si es 100; el género se omite si no tiene género.
## Puede llenarse parcialmente en Team Preview (ciertas formas y shininess
## no son visibles ahí), y puede cambiar durante el primer switch-in,
## pero no cambia después durante el resto de la partida.
## Ejemplos: "Mimikyu, L50, F", "Steelix, M, shiny"
var details: String = ""

## "{ident}|{details}". Se guarda para facilitar búsquedas.
## Igual que ident, vacío hasta el primer switch-in, y solo cambia ahí.
var searchid: String = ""

var name: String = ""

var side: Variant # referencia al Side dueño de este Pokémon
var slot: int = 0

var fainted: bool = false
var hp: int = 0
var maxhp: int = 1000
var level: int = 100
var gender: String = "N" # Dex.GenderName
var shiny: bool = false

var hpcolor: String = "g" # HPColor
var moves: Array[String] = []
var ability: String = ""
var base_ability: String = ""
var item: String = ""
var item_effect: String = ""
var prev_item: String = ""
var prev_item_effect: String = ""
var nature = null # Dex.NatureName | null
var terastallized: String = ""
var tera_type: String = ""
var modded_type: Array[String] = [] # Dex.TypeName[]

var boosts: Dictionary = {} # { stat: String -> valor: int }
var status: String = "" # Dex.StatusName | "tox" | "" | "???"
var status_stage: int = 0
var volatiles: Dictionary = {} # { effectid: String -> EffectState }
var turnstatuses: Dictionary = {} # { effectid: String -> EffectState }
var movestatuses: Dictionary = {} # { effectid: String -> EffectState }
var last_move: String = ""

## Array de pares [moveName, ppUsed]
var move_track: Array = [] # Array[Array] -> [String, PPState]
var status_data: Dictionary = {"sleep_turns": 0, "toxic_turns": 0}
var times_attacked: int = 0

var sprite: Sprite2D


func _init(data: Dictionary, p_side: Side) -> void:
	side = weakref(p_side)
	species_forme = data.get("species_forme", "")

	details = data.get("details", "")
	name = data.get("name", "")
	level = data.get("level", 100)
	shiny = data.get("shiny", false)
	gender = data.get("gender", "N") if data.get("gender", "N") != "" else "N"
	ident = data.get("ident", "")
	terastallized = data.get("terastallized", "")
	searchid = data.get("searchid", "")
	
	var battle: Battle = p_side.battle_ref.get_ref()
	sprite = battle.add_pokemon_sprite(self)
