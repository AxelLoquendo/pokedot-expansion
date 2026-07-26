class_name Side
extends RefCounted

var battle_ref: Variant
var name: String = ""
var id: String = ""
var sideid: String # SideID: "p1" | "p2" | "p3" | "p4"
var n: int
var is_far: bool
var foe: Side = null
var ally: Side = null
var avatar: String = "unknown"
var badges: Array[String] = []
var rating: String = ""
var total_pokemon: int = 6
var x: float = 0
var y: float = 0
var z: float = 0
var missed_pokemon: Pokemon = null

var wisher: Pokemon = null

var active: Array = [null] # Array[Pokemon] (puede contener null)
var last_pokemon: Pokemon = null
var pokemon: Array[Pokemon] = []
var open_team_sheet: bool = false

## { id: String -> [effectName, levels, minDuration, maxDuration] }
var side_conditions: Dictionary = {}
var faint_counter: int = 0


func _init(p_battle: Battle, p_n: int) -> void:
	battle_ref = weakref(p_battle)
	n = p_n
	var sideids := ["p1", "p2", "p3", "p4"]
	sideid = sideids[n]
	is_far = bool(n % 2)

func add_pokemon(name: String, ident: String, details: String, replace_slot = -1) -> Pokemon:
  # const data = this.battle.parseDetails(name, ident, details);
	var battle: Battle = battle_ref.get_ref()

	var data := battle.parse_details(name, ident, details)
	var poke := Pokemon.new(data, self)

	if replace_slot >= 0:
		pokemon[replace_slot] = poke
	else:
		pokemon.push_back(poke)

	#updateSidebar
	
	return poke
  
