class_name Side
extends RefCounted

var battle: Battle
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

## { condition_id: String -> [effect_name, levels, min_duration, max_duration] }
var side_conditions: Dictionary = { }
var faint_counter: int = 0


func _init(p_battle: Battle, p_n: int) -> void:
	battle = p_battle
	n = p_n
	var sideids := ["p1", "p2", "p3", "p4"]
	sideid = sideids[n]
	is_far = bool(n % 2)


func roll_trainer_sprites() -> void:
	var sprites := ["lucas", "dawn", "ethan", "lyra", "hilbert", "hilda"]
	avatar = sprites[randi() % sprites.size()]


func behindx(offset: float) -> float:
	return x + (-1.0 if not is_far else 1.0) * offset


func behindy(offset: float) -> float:
	return y + (1.0 if not is_far else -1.0) * offset


func leftof(offset: float) -> float:
	return (-1.0 if not is_far else 1.0) * offset


func behind(offset: float) -> float:
	return z + (-1.0 if not is_far else 1.0) * offset


func clear_pokemon() -> void:
	for p in pokemon:
		p.destroy()
	pokemon = []
	for i in range(active.size()):
		active[i] = null
	last_pokemon = null


func reset() -> void:
	clear_pokemon()
	side_conditions = { }
	faint_counter = 0


func set_avatar(p_avatar: String) -> void:
	avatar = p_avatar


func set_name(p_name: String, p_avatar: String = "") -> void:
	if p_name != "":
		name = p_name
	id = to_id(name)
	if p_avatar != "":
		set_avatar(p_avatar)
	else:
		roll_trainer_sprites()
		if foe != null and avatar == foe.avatar:
			roll_trainer_sprites()


# effect Dex.Effect -> Dictionary
func add_side_condition(effect: Dictionary, persist: bool) -> void:
	var condition: String = effect.id
	if side_conditions.has(condition):
		if condition == "spikes" or condition == "toxicspikes":
			side_conditions[condition][1] += 1
		battle.add_side_condition(n, condition)
		return

	# Las condiciones de bando funcionan como: [effect_name, levels, min_duration, max_duration]
	match condition:
		"auroraveil":
			side_conditions[condition] = [effect.name, 1, 5, 8]
		"reflect":
			side_conditions[condition] = [effect.name, 1, 5, (8 if battle.gen >= 4 else 0)]
		"safeguard":
			side_conditions[condition] = [effect.name, 1, (7 if persist else 5), 0]
		"lightscreen":
			side_conditions[condition] = [effect.name, 1, 5, (8 if battle.gen >= 4 else 0)]
		"mist":
			side_conditions[condition] = [effect.name, 1, 5, 0]
		"tailwind":
			var duration: int
			if battle.gen >= 5:
				duration = 6 if persist else 4
			else:
				duration = 5 if persist else 3
			side_conditions[condition] = [effect.name, 1, duration, 0]
		"luckychant":
			side_conditions[condition] = [effect.name, 1, 5, 0]
		"futuresight":
			side_conditions[condition] = ["Future Sight", 1, 3, 0]
		"doomdesire":
			side_conditions[condition] = ["Doom Desire", 1, 3, 0]
		"stealthrock", "spikes", "toxicspikes", "stickyweb":
			side_conditions[condition] = [effect.name, 1, 0, 0]
		"gmaxwildfire", "gmaxvolcalith", "gmaxvinelash", "gmaxcannonade":
			side_conditions[condition] = [effect.name, 1, 4, 0]
		"grasspledge":
			side_conditions[condition] = ["Swamp", 1, 4, 0]
		"waterpledge":
			side_conditions[condition] = ["Rainbow", 1, 4, 0]
		"firepledge":
			side_conditions[condition] = ["Sea of Fire", 1, 4, 0]
		_:
			side_conditions[condition] = [effect.name, 1, 0, 0]

	battle.add_side_condition(n, condition)


func remove_side_condition(condition: String) -> void:
	var cond_id := to_id(condition)
	if not side_conditions.has(cond_id):
		return
	side_conditions.erase(cond_id)
	battle.remove_side_condition(n, cond_id)


func add_pokemon(p_name: String, ident: String, details: String, replace_slot: int = -1) -> Pokemon:
	var old_pokemon: Pokemon = pokemon[replace_slot] if replace_slot >= 0 else null

	var data := battle.parse_details(p_name, ident, details)
	var poke := Pokemon.new(data, self)
	if old_pokemon != null:
		poke.item = old_pokemon.item
		poke.base_ability = old_pokemon.base_ability
		poke.tera_type = old_pokemon.tera_type

	if poke.ability == "" and poke.base_ability != "":
		poke.ability = poke.base_ability
	poke.reset()
	if old_pokemon != null and old_pokemon.move_track.size() > 0:
		poke.move_track = old_pokemon.move_track
	if old_pokemon != null and old_pokemon.nature != null:
		poke.nature = old_pokemon.nature

	if replace_slot >= 0:
		pokemon[replace_slot] = poke
	else:
		pokemon.append(poke)

	if pokemon.size() > total_pokemon or battle.species_clause:
		# comprobar Illusion
		var existing_table: Dictionary = { } # searchid: String -> index: int
		var to_remove := -1
		for poke1i in range(pokemon.size()):
			var poke1 := pokemon[poke1i]
			if poke1.searchid == "":
				continue
			if existing_table.has(poke1.searchid):
				var poke2i: int = existing_table[poke1.searchid]
				var poke2 := pokemon[poke2i]
				if poke == poke1:
					to_remove = poke2i
				elif poke == poke2:
					to_remove = poke1i
				elif active.has(poke1):
					to_remove = poke2i
				elif active.has(poke2):
					to_remove = poke1i
				elif poke1.fainted and not poke2.fainted:
					to_remove = poke2i
				else:
					to_remove = poke1i
				break
			existing_table[poke1.searchid] = poke1i

		if to_remove >= 0:
			if pokemon[to_remove].fainted:
				# Un Pokémon debilitado en realidad era un Zoroark
				var illusion_found: Pokemon = null
				for cur_poke in pokemon:
					if cur_poke == poke:
						continue
					if cur_poke.fainted:
						continue
					if active.has(cur_poke):
						continue
					if cur_poke.species_forme == "Zoroark" or cur_poke.species_forme == "Zorua" or cur_poke.ability == "Illusion":
						illusion_found = cur_poke
						break
				if illusion_found == null:
					# Esto es Hackmons; adivinamos un Pokémon no debilitado al azar.
					# Esto mantiene correcto el conteo de debilitados, y eventualmente
					# se corregirá conforme las suposiciones incorrectas se cambien
					# y se vuelvan a adivinar.
					for cur_poke in pokemon:
						if cur_poke == poke:
							continue
						if cur_poke.fainted:
							continue
						if active.has(cur_poke):
							continue
						illusion_found = cur_poke
						break
				if illusion_found != null:
					illusion_found.fainted = true
					illusion_found.hp = 0
					illusion_found.status = ""
			pokemon.remove_at(to_remove)

	battle.update_sidebar(self)

	return poke


func switch_in(p_pokemon: Pokemon, kw_args: Dictionary, slot: int = p_pokemon.slot) -> void:
	active[slot] = p_pokemon
	p_pokemon.slot = slot
	p_pokemon.clear_volatile()
	p_pokemon.last_move = ""
	battle.last_move = "switch-in"
	#TODO
	#var effect = Dex.get_effect(kw_args.get("from", ""))
	#if effect.id in ["batonpass", "zbatonpass", "shedtail"]:
		#p_pokemon.copy_volatile_from(last_pokemon, "shedtail" if effect.id == "shedtail" else "batonpass")
	#elif battle.tier.contains("Relay Race") and effect.id == "":
		#if last_pokemon != null and not last_pokemon.fainted:
			#p_pokemon.copy_volatile_from(last_pokemon, "batonpass")
#
	#battle.anim_summon(p_pokemon, slot)


func drag_in(p_pokemon: Pokemon, slot: int = p_pokemon.slot) -> void:
	var old_pokemon: Pokemon = active[slot]
	if old_pokemon == p_pokemon:
		return
	last_pokemon = old_pokemon
	if old_pokemon != null:
		battle.anim_drag_out(old_pokemon)
		old_pokemon.clear_volatile()
	p_pokemon.clear_volatile()
	p_pokemon.last_move = ""
	battle.last_move = "switch-in"
	active[slot] = p_pokemon
	p_pokemon.slot = slot

	battle.anim_drag_in(p_pokemon, slot)


func replace(p_pokemon: Pokemon, slot: int = p_pokemon.slot) -> void:
	var old_pokemon: Pokemon = active[slot]
	if p_pokemon == old_pokemon:
		return
	last_pokemon = old_pokemon
	p_pokemon.clear_volatile()
	if old_pokemon != null:
		p_pokemon.last_move = old_pokemon.last_move
		p_pokemon.hp = old_pokemon.hp
		p_pokemon.maxhp = old_pokemon.maxhp
		p_pokemon.hpcolor = old_pokemon.hpcolor
		p_pokemon.status = old_pokemon.status
		p_pokemon.copy_volatile_from(old_pokemon, "illusion")
		p_pokemon.status_data = old_pokemon.status_data.duplicate()
		if old_pokemon.terastallized != "":
			p_pokemon.terastallized = old_pokemon.terastallized
			p_pokemon.tera_type = old_pokemon.terastallized
			old_pokemon.terastallized = ""
			old_pokemon.tera_type = ""
		# no sabemos nada del pokémon ilusionado excepto que no está debilitado
		# técnicamente también sabemos su status, pero solo al final del turno, no aquí
		old_pokemon.fainted = false
		old_pokemon.hp = old_pokemon.maxhp
		old_pokemon.status = "???"

	active[slot] = p_pokemon
	p_pokemon.slot = slot

	if old_pokemon != null:
		battle.anim_unsummon(old_pokemon, true)
	battle.anim_summon(p_pokemon, slot, true)


func switch_out(p_pokemon: Pokemon, kw_args: Dictionary, slot: int = p_pokemon.slot) -> void:
	# effect Dex.Effect -> Dictionary
	var effect: Dictionary = { }
	# Dex.get_effect(kw_args.get("from", ""))
	var is_relay_race_no_effect := false
	# battle.tier.contains("Relay Race") and effect.id == ""

	if not (effect.id in ["batonpass", "zbatonpass"]) and not is_relay_race_no_effect:
		p_pokemon.clear_volatile()
		if effect.id == "shedtail":
			p_pokemon.volatiles = { "substitute": ["substitute"] }
			if p_pokemon.sprite:
				p_pokemon.sprite.anim_sub(true)
	else:
		p_pokemon.remove_volatile("transform")
		p_pokemon.remove_volatile("formechange")

	# if not (effect.id in ["batonpass", "zbatonpass", "shedtail", "teleport"]) and not is_relay_race_no_effect:
	# 	battle.log(["switchout", p_pokemon.ident], {"from": effect.id})

	p_pokemon.status_data.toxic_turns = 0
	if battle.gen == 5:
		p_pokemon.status_data.sleep_turns = 0
	if battle.tier.contains("Champions"):
		p_pokemon.times_attacked = 0

	last_pokemon = p_pokemon
	active[slot] = null

	battle.anim_unsummon(p_pokemon)


func swap_to(p_pokemon: Pokemon, slot: int) -> void:
	if p_pokemon.slot == slot:
		return
	var target: Pokemon = active[slot]

	var oslot: int = p_pokemon.slot

	p_pokemon.slot = slot
	if target != null:
		target.slot = oslot

	active[slot] = p_pokemon
	active[oslot] = target

	battle.anim_unsummon(p_pokemon, true)
	if target != null:
		battle.anim_unsummon(target, true)

	battle.anim_summon(p_pokemon, slot, true)
	if target != null:
		battle.anim_summon(target, oslot, true)


func swap_with(p_pokemon: Pokemon, target: Pokemon, kw_args: Dictionary) -> void:
	# método provisto solo por compatibilidad hacia atrás
	if p_pokemon == target:
		return

	var oslot: int = p_pokemon.slot
	var nslot: int = target.slot

	p_pokemon.slot = nslot
	target.slot = oslot
	active[nslot] = p_pokemon
	active[oslot] = target

	battle.anim_unsummon(p_pokemon, true)
	battle.anim_unsummon(target, true)

	battle.anim_summon(p_pokemon, nslot, true)
	battle.anim_summon(target, oslot, true)


func faint(p_pokemon: Pokemon, slot: int = p_pokemon.slot) -> void:
	p_pokemon.clear_volatile()
	last_pokemon = p_pokemon
	active[slot] = null

	p_pokemon.fainted = true
	p_pokemon.hp = 0
	p_pokemon.terastallized = ""

	var tera_regex := RegEx.create_from_string("(?i), tera:[a-z]+")
	p_pokemon.details = tera_regex.sub(p_pokemon.details, "")
	p_pokemon.searchid = tera_regex.sub(p_pokemon.searchid, "")

	if p_pokemon.side.faint_counter < 100:
		p_pokemon.side.faint_counter += 1

	battle.anim_faint(p_pokemon)


func destroy() -> void:
	clear_pokemon()
	battle = null
	foe = null


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
