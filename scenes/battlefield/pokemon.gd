class_name Pokemon
extends RefCounted

## String con info extraíble de mensajes textuales: side_ref, nickname.
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

var side: Side # referencia al Side dueño de este Pokémon
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

var boosts: Dictionary = { } # { stat: String -> valor: int }
var status: String = "" # Dex.StatusName | "tox" | "" | "???"
var status_stage: int = 0
var volatiles: Dictionary = { } # { effectid: String -> EffectState }
var turnstatuses: Dictionary = { } # { effectid: String -> EffectState }
var movestatuses: Dictionary = { } # { effectid: String -> EffectState }
var last_move: String = ""

## Array de pares [moveName, ppUsed]
var move_track: Array = [] # Array[Array] -> [String, PPState]
var status_data: Dictionary = { "sleep_turns": 0, "toxic_turns": 0 }
var times_attacked: int = 0

var sprite


func _init(data: Dictionary, p_side: Side) -> void:
	side = p_side
	species_forme = data.get("species_forme", "")

	details = data.get("details", "")
	name = data.get("name", "")
	level = data.get("level", 100)
	shiny = data.get("shiny", false)
	gender = data.get("gender", "N") if data.get("gender", "N") != "" else "N"
	ident = data.get("ident", "")
	terastallized = data.get("terastallized", "")
	searchid = data.get("searchid", "")

	sprite = p_side.battle.add_pokemon_sprite(self)


func check_details(details: String = "") -> bool:
	if details == "":
		return false
	if details == self.details:
		return true
	if searchid != "":
		return false

	if details.contains(", shiny"):
		if check_details(details.replace(", shiny", "")):
			return true

	# la forma real estaba oculta en el Team Preview
	var regex := RegEx.create_from_string("(-[A-Za-z0-9-]+)?(, |$)")
	var result := regex.search(details)
	if result:
		var group2 := result.get_string(2)
		var matched_text := result.get_string(0)
		var start := result.get_start(0)
		var new_details := details.substr(0, start) + "-*" + group2 + details.substr(start + matched_text.length())
		details = new_details

	return details == self.details


func health_parse(hpstring: String, parsedamage: bool = false, heal: bool = false) -> Array:
	if hpstring == null or hpstring.length() == 0:
		return []

	var paren_index := hpstring.rfind("(")
	if paren_index >= 0: # Esta validacion corresponde al formato de hpstring antiguo "32 (18% dmg)"
		assert(false, "No manejo del formato de hpstring antiguo")

	var oldhp: float = 0.0 if fainted else (hp if hp else 1.0)
	var oldmaxhp: float = maxhp
	var oldwidth: float = hp_width(100)
	var oldcolor: String = hpcolor

	side.battle.parse_health(hpstring, self)
	if oldmaxhp == 0: # maxhp no se conocía antes de parsear este mensaje
		oldmaxhp = oldhp
		oldhp = oldmaxhp # equivalente a: oldmaxhp = oldhp = this.maxhp

	# NOTA: la línea de arriba reproduce "oldmaxhp = oldhp = this.maxhp" del original;
	# ver aclaración más abajo sobre el orden correcto.

	var oldnum: int = 0
	if oldhp:
		oldnum = int(floor(maxhp * oldhp / oldmaxhp))
		if oldnum == 0:
			oldnum = 1

	var delta: float = hp - oldnum
	var deltawidth: float = hp_width(100) - oldwidth
	return [delta, maxhp, deltawidth, oldnum, oldcolor]


func hp_width(max_width: int) -> int:
	if fainted or not hp:
		return 0

	# caso especial para HP muy bajo...
	if hp == 1 and maxhp > 45:
		return 1

	if maxhp == 48:
		# Dibuja la barra hasta la mitad del rango.
		# Esto afecta SOLO el ancho visual de la barra; no afecta
		# de ninguna forma los rangos mostrados en otro lugar.
		var range := Pokemon.get_pixel_range(hp, hpcolor)
		var ratio: float = (range[0] + range[1]) / 2.0
		var rounded := roundi(max_width * ratio)
		return rounded if rounded != 0 else 1

	var width := roundi(float(hp) / float(maxhp) * max_width)
	if width == 0:
		width = 1
	return max_width - 1 if (hp < maxhp and width == max_width) else width


static func get_pixel_range(pixels: int, color: String) -> Array:
	var epsilon := 0.5 / 714.0

	if pixels == 0:
		return [0.0, 0.0]
	if pixels == 1:
		return [0.0 + epsilon, 2.0 / 48.0 - epsilon]

	if color != "":
		if pixels == 9:
			if color == "y": # ratio es > 0.2
				return [0.2 + epsilon, 10.0 / 48.0 - epsilon]
			elif color == "r": # ratio es <= 0.2
				return [9.0 / 48.0, 0.2]
		if pixels == 24:
			if color == "g": # ratio es > 0.5
				return [0.5 + epsilon, 25.0 / 48.0 - epsilon]
			elif color == "y": # ratio es exactamente 0.5
				return [0.5, 0.5]

	if pixels == 48:
		return [1.0, 1.0]

	return [pixels / 48.0, (pixels + 1) / 48.0 - epsilon]


func get_ident() -> String:
	var slots := ["a", "b", "c", "d", "e", "f"]
	return ident.substr(0, 2) + slots[slot] + ident.substr(2)


func remove_volatile(volatile: String) -> void:
	side.battle.remove_effect(self, volatile)
	if not has_volatile(volatile):
		return
	volatiles.erase(volatile)


func add_volatile(volatile: String, args: Array = []) -> void:
	if has_volatile(volatile) and args.is_empty():
		return
	volatiles[volatile] = [volatile] + args
	side.battle.add_effect(self, volatile)


func has_volatile(volatile: String) -> bool:
	return volatiles.has(volatile)


func remove_turnstatus(volatile: String) -> void:
	side.battle.remove_effect(self, volatile)
	if not has_turnstatus(volatile):
		return
	turnstatuses.erase(volatile)


func add_turnstatus(volatile: String) -> void:
	var vol_id := to_id(volatile)
	side.battle.add_effect(self, vol_id)
	if has_turnstatus(vol_id):
		return
	turnstatuses[vol_id] = [vol_id]


func has_turnstatus(volatile: String) -> bool:
	return turnstatuses.has(volatile)


func clear_turnstatuses() -> void:
	for id in turnstatuses.keys():
		remove_turnstatus(id)
	turnstatuses = { }
	side.battle.update_statbar(self)


func remove_movestatus(volatile: String) -> void:
	side.battle.remove_effect(self, volatile)
	if not has_movestatus(volatile):
		return
	movestatuses.erase(volatile)


func add_movestatus(volatile: String) -> void:
	var vol_id := to_id(volatile)
	if has_movestatus(vol_id):
		return
	movestatuses[vol_id] = [vol_id]
	side.battle.add_effect(self, vol_id)


func has_movestatus(volatile: String) -> bool:
	return movestatuses.has(volatile)


func clear_movestatuses() -> void:
	for id in movestatuses.keys():
		remove_movestatus(id)
	movestatuses = { }


func clear_volatiles() -> void:
	#TODO
	#volatiles = { }
	#clear_turnstatuses()
	#clear_movestatuses()
	#side.battle.clear_effects(self)
	pass
	


func _merge_pp(entry: Array, pp: Variant) -> Variant:
	var pp_used: Variant = entry[1]

	if typeof(pp_used) == TYPE_INT or typeof(pp_used) == TYPE_FLOAT:
		if typeof(pp) == TYPE_INT or typeof(pp) == TYPE_FLOAT:
			pp_used = pp_used + pp
		else:
			pp_used = [pp_used + pp[0], pp_used + pp[1]]
	else:
		if typeof(pp) == TYPE_INT or typeof(pp) == TYPE_FLOAT:
			pp_used[0] += pp
			pp_used[1] += pp
		else:
			pp_used[0] += pp[0]
			pp_used[1] += pp[1]

	if typeof(pp_used) == TYPE_INT or typeof(pp_used) == TYPE_FLOAT:
		if pp_used < 0:
			pp_used = 0
	else:
		if pp_used[0] < 0:
			pp_used[0] = 0
		if pp_used[1] < 0:
			pp_used[1] = 0

		#TODO
		# var move := side.battle.dex.moves.get(entry[0])
		# var maxpp: float = move.pp if (move.pp == 1 or move.no_pp_boosts) else move.pp * 8.0 / 5.0

		# if side.battle.tier.contains("Champions"):
		# 	maxpp = 20 if move.pp > 20 else move.pp
		# 	maxpp = move.pp if (move.pp == 1 or move.no_pp_boosts) else (move.pp / 5.0 + 1) * 4.0

		# if pp_used[0] > maxpp:
		# 	pp_used[0] = maxpp
		# if pp_used[0] < pp_used[1]:
		# 	pp_used[0] = pp_used[1]
		# if pp_used[0] == pp_used[1]:
		# 	pp_used = pp_used[0]

	# return pp_used
	return 0


func remember_move(move_name_in: String, pp: Variant = 1, recursion_source: String = "") -> void:
	if recursion_source == ident:
		return

	#TODO
	# var move_name := side.battle.dex.moves.get(move_name_in).name
	var move_name := ""

	if move_name.begins_with("*"):
		return
	if move_name == "Struggle":
		return

	if volatiles.has("transform"):
		# asegura que no haya recursión infinita si ambos Pokémon están
		# transformados el uno en el otro
		var source := recursion_source if recursion_source != "" else ident
		var transformed_into: Pokemon = volatiles["transform"][1]
		transformed_into.remember_move(move_name, 0, source)
		move_name = "*" + move_name

	for entry in move_track:
		if move_name == entry[0]:
			entry[1] = _merge_pp(entry, pp)
			return

	move_track.append([move_name, pp])


func remember_ability(ability_name: String, is_not_base: bool = false) -> void:
	#TODO
	pass
	# var ability_final := Dex.abilities.get(ability_name).name
	# ability = ability_final
	# if base_ability == "" and not is_not_base:
	# 	base_ability = ability_final


## Devuelve un texto legible del boost actual de una estadística,
## ej. "2x Atk" o "0.5x SpD".
func get_boost(boost_stat: String) -> String:
	var boost_stat_table := {
		"atk": "Atk",
		"def": "Def",
		"spa": "SpA",
		"spd": "SpD",
		"spe": "Spe",
		"accuracy": "Accuracy",
		"evasion": "Evasion",
		"spc": "Spc",
	}

	if not boosts.has(boost_stat) or boosts[boost_stat] == 0:
		return "1x " + boost_stat_table[boost_stat]

	if boosts[boost_stat] > 6:
		boosts[boost_stat] = 6
	if boosts[boost_stat] < -6:
		boosts[boost_stat] = -6

	var is_rby: bool = side.battle.gen <= 1 and not side.battle.tier.contains("Stadium")

	if not is_rby and (boost_stat == "accuracy" or boost_stat == "evasion"):
		if boosts[boost_stat] > 0:
			var good_boost_table := [
				"1x",
				"1.33x",
				"1.67x",
				"2x",
				"2.33x",
				"2.67x",
				"3x",
			]
			return good_boost_table[boosts[boost_stat]] + " " + boost_stat_table[boost_stat]

		var bad_boost_table := [
			"1x",
			"0.75x",
			"0.6x",
			"0.5x",
			"0.43x",
			"0.38x",
			"0.33x",
		]
		return bad_boost_table[-boosts[boost_stat]] + " " + boost_stat_table[boost_stat]

	if boosts[boost_stat] > 0:
		var good_boost_table := [
			"1x",
			"1.5x",
			"2x",
			"2.5x",
			"3x",
			"3.5x",
			"4x",
		]
		return good_boost_table[boosts[boost_stat]] + " " + boost_stat_table[boost_stat]

	var bad_boost_table := [
		"1x",
		"0.67x",
		"0.5x",
		"0.4x",
		"0.33x",
		"0.29x",
		"0.25x",
	]
	return bad_boost_table[-boosts[boost_stat]] + " " + boost_stat_table[boost_stat]


func get_weight_kg(server_pokemon = null) -> float:
	#TODO
	# var autotomize_factor := 0.0
	# if volatiles.has("autotomize"):
	# 	autotomize_factor = volatiles["autotomize"][1] * 100.0
	# return max(get_species(server_pokemon).weightkg - autotomize_factor, 0.1)
	return 0.1


func get_boost_type(boost_stat: String) -> String:
	if not boosts.has(boost_stat) or boosts[boost_stat] == 0:
		return "neutral"
	if boosts[boost_stat] > 0:
		return "good"
	return "bad"


func clear_volatile() -> void:
	ability = base_ability
	boosts = { }
	clear_volatiles()

	var i := 0
	while i < move_track.size():
		if move_track[i][0].begins_with("*"):
			move_track.remove_at(i)
		else:
			i += 1

	last_move = ""
	status_stage = 0
	status_data.toxic_turns = 0
	if side.battle.gen == 5:
		status_data.sleep_turns = 0


func copy_volatile_from(pokemon: Pokemon, copy_source: String) -> void:
	boosts = pokemon.boosts
	volatiles = pokemon.volatiles
	last_move = pokemon.last_move # creo

	if copy_source == "batonpass":
		var volatiles_to_remove := [
			"airballoon",
			"attract",
			"autotomize",
			"disable",
			"encore",
			"foresight",
			"gmaxchistrike",
			"imprison",
			"laserfocus",
			"mimic",
			"miracleeye",
			"nightmare",
			"saltcure",
			"smackdown",
			"stockpile1",
			"stockpile2",
			"stockpile3",
			"syrupbomb",
			"torment",
			"typeadd",
			"typechange",
			"yawn",
		]
		# TODO
		# for stat_name in Dex.stat_names_except_hp:
		# 	volatiles_to_remove.append("protosynthesis" + stat_name)
		# 	volatiles_to_remove.append("quarkdrive" + stat_name)

		# for volatile in volatiles_to_remove:
		# 	volatiles.erase(volatile)

	# Shed Tail no necesita manejo especial porque el origen ya tiene
	# sus volatiles (excepto Substitute) limpiados en switch_out.
	volatiles.erase("transform")
	volatiles.erase("formechange")

	pokemon.boosts = { }
	pokemon.volatiles = { }
	pokemon.side.battle.remove_transform(pokemon)
	pokemon.status_stage = 0


## Copia los tipos de otro Pokémon (usado en Transform, por ejemplo).
func copy_types_from(pokemon: Pokemon, preterastallized: bool = false) -> void:
	var result := pokemon.get_types(null, preterastallized)
	var types: Array = result[0]
	var added_type: String = result[1]

	add_volatile("typechange", ["/".join(types)])
	if added_type != "":
		add_volatile("typeadd", [added_type])
	else:
		remove_volatile("typeadd")


func get_types(server_pokemon = null, preterastallized: bool = false) -> Array:
	var types: Array

	if not preterastallized and terastallized != "" and terastallized != "Stellar":
		types = [terastallized]
	elif volatiles.has("typechange"):
		types = volatiles["typechange"][1].split("/")
	elif modded_type.size() > 0:
		types = modded_type
	else:
		#TODO
		# types = get_species(server_pokemon).types
		pass

	if has_turnstatus("roost") and types.has("Flying"):
		types = types.filter(func(type_name): return type_name != "Flying")
		if types.is_empty():
			types = ["Normal"]

	var added_type: String = volatiles["typeadd"][1] if volatiles.has("typeadd") else ""
	return [types, added_type]


## Determina si el Pokémon está "en el suelo" (afectado por movimientos
## de tierra como Earthquake), considerando Gravity, Ingrain, Smackdown,
## Iron Ball, Levitate, Magnet Rise, Telekinesis, Air Balloon y tipo Volador.
func is_grounded(server_pokemon = null) -> bool:
	var battle := side.battle

	if battle.has_pseudo_weather("Gravity"):
		return true
	elif volatiles.has("ingrain") and battle.gen >= 4:
		return true
	elif volatiles.has("smackdown"):
		return true

	var item := to_id(server_pokemon.item if server_pokemon else item)
	var ability := to_id(effective_ability(server_pokemon))

	if battle.has_pseudo_weather("Magic Room") or volatiles.has("embargo") or ability == "klutz":
		item = ""

	if item == "ironball":
		return true
	if ability == "levitate" or ability == "eelevate":
		return false
	if volatiles.has("magnetrise") or volatiles.has("telekinesis"):
		return false
	if item == "airballoon":
		return false

	return not get_type_list(server_pokemon).has("Flying")


## Devuelve el nombre de la habilidad "efectiva" del Pokémon, o "" si
## está suprimida (por Gastro Acid, Neutralizing Gas, fainted, o
## Transform contra una habilidad que lo impide).
func effective_ability(server_pokemon = null) -> String:
	var ability_name := ""
	if server_pokemon and server_pokemon.ability != "":
		ability_name = server_pokemon.ability
	elif ability != "":
		ability_name = ability
	elif server_pokemon and server_pokemon.base_ability != "":
		ability_name = server_pokemon.base_ability

	return ""
	#####
	#TODO
	# var ability_data := side.battle.dex.abilities.get(ability_name)

	# if fainted \
	# 		or (volatiles.has("transform") and ability_data.flags.get("notransform", false)) \
	# 		or (not ability_data.flags.get("cantsuppress", false) and (side.battle.ngas_active() or volatiles.has("gastroacid"))):
	# 	return ""

	# return ability_data.name
	return ""


## Lista de tipos incluyendo el tipo añadido (si existe), como array plano.
func get_type_list(server_pokemon = null, preterastallized: bool = false) -> Array:
	var result := get_types(server_pokemon, preterastallized)
	var types: Array = result[0]
	var added_type: String = result[1]
	return types + [added_type] if added_type != "" else types


## Forma/especie actual, considerando cambios de forma (ej. Mega, Zen Mode).
func get_species_forme(server_pokemon = null) -> String:
	if volatiles.has("formechange"):
		return volatiles["formechange"][1]
	return server_pokemon.species_forme if server_pokemon else species_forme


func get_species(server_pokemon = null):
	return side.battle.dex.species.get(get_species_forme(server_pokemon))


func get_base_species():
	return side.battle.dex.species.get(species_forme)


## Reinicia el Pokémon a un estado "limpio" (usado en Team Preview / al
## reconstruir el equipo), curando su HP y status pero conservando nombre.
func reset() -> void:
	clear_volatile()
	hp = maxhp
	fainted = false
	status = ""
	move_track = []
	name = name if name != "" else species_forme


static func to_id(value: Variant) -> String:
	var text: Variant = value

	# Si es un Dictionary con clave "id" o "userid", usar ese valor.
	if typeof(text) == TYPE_DICTIONARY:
		if text.has("id") and text["id"] != null and text["id"] != "":
			text = text["id"]
		elif text.has("userid") and text["userid"] != null and text["userid"] != "":
			text = text["userid"]
	# Si es un Object con propiedad "id" o "userid" (ej. una clase tuya).
	elif typeof(text) == TYPE_OBJECT and text != null:
		if "id" in text and text.id != null and text.id != "":
			text = text.id
		elif "userid" in text and text.userid != null and text.userid != "":
			text = text.userid

	# Solo strings o números son válidos; cualquier otra cosa da id vacío.
	if typeof(text) != TYPE_STRING and typeof(text) != TYPE_INT and typeof(text) != TYPE_FLOAT:
		return ""

	var regex := RegEx.create_from_string("[^a-z0-9]+")
	return regex.sub(str(text).to_lower(), "", true)
