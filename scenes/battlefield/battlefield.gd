class_name Battle
extends Node2D

signal battle_finished(result: String)

var is_animation_running := false
var packet: String
var at_queue_end := true
var ended := false
var step_queue: Array[String]
var current_step := 0
var pbattlepeer: PBattlePeer
var thread: Thread

# ── Battle ──────────────────────────────────────────────────────────────────────
var my_side: Side
var near_side: Side
var far_side: Side
var p1: Side
var p2: Side
var sides: Array[Side]
var turns_since_moved: int
var game_type: String
var end_last_turn_pending: bool
var tier: String
var gen: int = 9
var species_clause: bool
var last_move: String

@onready var sprites = [$Base/Pokemon, $BaseFoe/PokemonFoe]


# ── Cámara ─────────────────────────────────────────────────────────────────────
@onready var camera: Camera2D = $Camera2D

func _physics_process(_delta: float) -> void:
	if pbattlepeer == null:
		return

	pbattlepeer.poll()
	var ready_state: int = pbattlepeer.get_ready_state()

	if ready_state == PBattlePeer.STATE_OPEN:
		if pbattlepeer.get_available_packet_count():
			var packet := pbattlepeer.get_packet()
			step_queue.push_back(packet)
			print(packet)

			if at_queue_end and current_step < step_queue.size():
				at_queue_end = false
				next_step()
			# is_animation_running = true
			# await handle_action(packet)
			# is_animation_running = false


func _exit_tree() -> void:
	thread.wait_to_finish()


func should_step() -> bool:
	return not at_queue_end


func next_step() -> void:
	while true:
		if at_queue_end == true:
			return

		run(step_queue[current_step])
		current_step += 1

		if current_step >= step_queue.size():
			at_queue_end = true


func run(str: String) -> void:
	if str.length() == 0:
		return

	var battle_line := parse_battle_line(str)
	var args := battle_line.args
	var kw_args := battle_line.kw_args

	var prev_args: PackedStringArray
	var prev_kw_args: Dictionary
	var prev_line: String

	if current_step > 0:
		prev_line = step_queue[current_step - 1]

	if prev_line.begins_with("|-"): # La linea anterior corresponde a un minor action
		var prev_battle_line := parse_battle_line(str)
		prev_args = prev_battle_line.args
		prev_kw_args = prev_battle_line.kw_args

	# La comprobación de igualdad con detailschange es algo heredado del código original
	# no se que significa, y si tiene sentido en esta base de código
	if args[0].begins_with("-") or args[0] == "detailschange":
		run_minor(args, kw_args, prev_args, prev_kw_args)
	else:
		run_major(args, kw_args)

func log_step(args: Variant, kw_args: Variant={}) -> void:
	pass

func _start() -> void:
	log_step(["start"])
	reset_turns_since_moved()


func reset_turns_since_moved() -> void:
	turns_since_moved = 0;

func update_sidebar(side: Side) -> void:
	#TODO
	pass

func remove_effect(id: Variant, instant: Variant) -> void:
	#TODO
	pass

func add_effect(id: Variant, instant: Variant) -> void:
	#TODO
	pass

func clear_effects() -> void:
	#TODO
	pass

func remove_transform(pokemon: Pokemon) -> void:
	#TODO
	pass


func remember_team_preview_pokemon(sideid: String, details: String) -> Pokemon:
	var parsed_pokemon_id := parse_pokemon_id(sideid)
	var siden: int = parsed_pokemon_id.siden

	return sides[siden].add_pokemon("", "", details)

## Toma [param pokemonid] que puede llegar hacer:
## [code]p1[/code] | [code]p1: Dragonite[/code] | [code]p1a: Sparky[/code][br]
##
## Retorna un [Dictionary] que cuenta con las siguiente entradas:[br]
## [code]  name[/code][br]
## [code]  siden[/code][br]
## [code]  slot[/code][br]
## [code]  pokemonid[/code]
func parse_pokemon_id(pokemonid: String) -> Dictionary:
	var name := pokemonid

	var siden := -1
	var slot := -1

	# comprobar si se trata de un sideid o un pokemonid que corresponde a un pokemon inactivo
	if RegEx.create_from_string("^p[1-9]($|: )").search(name):
		siden = name.substr(1, 1).to_int() -1
		name = name.substr(4) # p1: Dragonite
													#     ^
	# comprobar si se trata de un pokemonid de corresponde a un pokemon activo
	elif RegEx.create_from_string("^p[1-9][a-f]: ").search(name):
		const SLOT_CHAR = { "a": 0, "b": 1, "c": 2, "d": 3, "e": 4, "f": 5 }

		siden = name.substr(1, 1).to_int() -1
		slot = SLOT_CHAR[name.substr(2, 1)]

		name = name.substr(5) # p1a: Dragonite
													#      ^
		pokemonid = "p%d: %s" % [siden + 1, name]

	return { "name": name, "siden": siden, "slot": slot, "pokemonid": pokemonid }


func parse_details(name: String, pokemonid: String, details: String, output: Dictionary={}) -> Dictionary:
	var is_team_preview: bool = name == ""
	output["details"] = details
	output["name"] = name
	output["species_forme"] = name
	output["level"] = 100
	output["shiny"] = false
	output["gender"] = ""
	output["ident"] = (pokemonid if not is_team_preview else "")
	output["searchid"] = ("%s|%s" % [pokemonid, details] if not is_team_preview else "")

	var split_details := details.split(", ")

	if split_details[-1].begins_with("tera:"):
		output["terastallized"] = split_details[-1].substr(5)
		split_details.remove_at(split_details.size() - 1)

	if split_details[-1] == "shiny":
		output["shiny"] = true
		split_details.remove_at(split_details.size() - 1)

	if split_details[-1] == "M" or split_details[-1] == "F":
		output["gender"] = split_details[-1]
		split_details.remove_at(split_details.size() - 1)

	if split_details.size() > 1 and split_details[1] != "":
		output["level"] = split_details[1].substr(1).to_int() if split_details[1].substr(1).is_valid_int() else 100
		if output["level"] == 0:
			output["level"] = 100

	if split_details.size() > 0 and split_details[0] != "":
		output["speciesForme"] = split_details[0]

	return output

func run_minor(args: PackedStringArray, kw_args: Dictionary, prev_args: PackedStringArray, prev_kw_args: Dictionary) -> void:
	match args[0]:
		"-damage":
			pass
		"-heal":
			pass
		"-sethp":
			pass
		"-boost":
			pass
		"-unboost":
			pass
		"-setboost":
			pass
		"-swapboost":
			pass
		"-clearpositiveboost":
			pass
		"-clearnegativeboost":
			pass
		"-copyboost":
			pass
		"-clearboost":
			pass
		"-invertboost":
			pass
		"-clearallboost":
			pass
		"-crit":
			pass
		"-supereffective":
			pass
		"-resisted":
			pass
		"-immune":
			pass
		"-miss":
			pass
		"-fail":
			pass
		"-block":
			pass
		"-center", "-notarget", "-ohko", "-combine", "-hitcount", "-waiting", "-zbroken":
			pass
		"-zpower":
			pass
		"-prepare":
			pass
		"-mustrecharge":
			pass
		"-status":
			pass
		"-curestatus":
			pass
		"-cureteam":
			pass
		"-item":
			pass
		"-enditem":
			pass
		"-ability":
			pass
		"-endability":
			pass
		"detailschange":
			pass
		"-transform":
			pass
		"-formechange":
			pass
		"-mega":
			pass
		"-primal", "-burst":
			pass
		"-terastallize":
			pass
		"-start":
			pass
		"-end":
			pass
		"-singleturn":
			pass
		"-singlemove":
			pass
		"-activate":
			pass
		"-sidestart":
			pass
		"-sideend":
			pass
		"-swapsideconditions":
			pass
		"-weather":
			pass
		"-fieldstart":
			pass
		"-fieldend":
			pass
		"-fieldactivate":
			pass
		"-anim":
			pass
		"-hint", "-message", "-candynamax":
			pass
		_:
			pass

# ─────── Scene ───────────────────────────────────────────────────
func update_statbars() -> void:
	for side in sides:
		for active in side.active:
			if active:
				active.sprite.update_statbar(active)

func update_statbar(pokemon: Pokemon, update_prevhp: bool=false, update_hp: bool=false) -> void:
	pokemon.sprite.update_statbar(pokemon, update_prevhp, update_hp)

func parse_health(hpstring: String, output: Pokemon) -> Variant:
	var parts := hpstring.split(" ")
	var hp: String = parts[0] if parts.size() > 0 else ""
	var status: String = parts[1] if parts.size() > 1 else ""

	# parseo de hp
	output["hpcolor"] = ""
	if hp == "0" or hp == "0.0":
		if not output.get("maxhp"):
			output["maxhp"] = 100
		output["hp"] = 0
	elif hp.find("/") > 0:
		var hp_parts := hp.split("/")
		var curhp := hp_parts[0]
		var maxhp := hp_parts[1]
		if not curhp.is_valid_float() or not maxhp.is_valid_float():
			return null
		output["hp"] = curhp.to_float()
		output["maxhp"] = maxhp.to_float()
		if output["hp"] > output["maxhp"]:
			output["hp"] = output["maxhp"]
		var colorchar := maxhp.substr(maxhp.length() - 1)
		if colorchar == "r" or colorchar == "y" or colorchar == "g":
			output["hpcolor"] = colorchar
	elif hp.is_valid_float():
		if not output.get("maxhp"):
			output["maxhp"] = 100
		output["hp"] = output["maxhp"] * hp.to_float() / 100.0

	# parseo de status
	if status == "":
		output["status"] = ""
	elif status == "par" or status == "brn" or status == "slp" or status == "frz" or status == "tox":
		output["status"] = status
	elif status == "psn" and output.get("status") != "tox":
		output["status"] = status
	elif status == "fnt":
		output["hp"] = 0
		output["fainted"] = true

	return output

func end_last_turn() -> void:
	if end_last_turn_pending:
		end_last_turn_pending = false
		update_statbars()

func get_switched_pokemon(pokemonid: String, details: String) -> Pokemon:
	var parsed_pokemon_id = parse_pokemon_id(pokemonid)

	var name = parsed_pokemon_id.name
	var siden = parsed_pokemon_id.siden
	var slot = parsed_pokemon_id.slot
	pokemonid = parsed_pokemon_id.pokemonid

	var searchid = pokemonid + "|" + details
	var side = sides[siden]

	# search inactive revealed pokemon
	for i in range(side.pokemon.size()):
		var pokemon: Pokemon = side.pokemon[i]

		if pokemon.fainted:
			continue
		# already active, can't be switching in
		if side.active.has(pokemon):
			continue
		# just switched out, can't be switching in
		if pokemon == side.last_pokemon and not side.active[slot]:
			continue
		
		if pokemon.searchid == searchid:
			# exact match
			if slot >= 0:
				pokemon.slot = slot
			return pokemon
		
		if not pokemon.searchid and pokemon.check_details(details):
			# switch-in matches Team Preview entry
			pokemon = side.add_pokemon(name, pokemonid, details, i)
			if slot >= 0:
				pokemon.slot = slot
			return pokemon

	var pokemon := side.add_pokemon(name, pokemonid, details)
	if slot >= 0:
		pokemon.slot = slot
	return pokemon


func update_weather() -> void:
	#TODO
	pass


func run_major(args: PackedStringArray, kw_args: Dictionary) -> void:
	#region

	match args[0]:
		"start":
			# this.nearSide.active[0] = null;
			# this.farSide.active[0] = null;
			# this.scene.resetSides();
			# this.start();
			_start()
		"upkeep":
			pass
		"turn":
			pass
		"tier":
			pass
		"gametype":
			game_type = args[1]
		"rule":
			pass
		"rated":
			pass
		"inactive":
			pass
		"inactiveoff":
			pass
		"join", "j", "J":
			pass
		"leave", "l", "L":
			pass
		"name", "n", "N":
			pass
		"player":
			pass
		"badge":
			pass
		"teamsize":
			pass
		"win", "tie":
			pass
		"prematureend":
			pass
		"clearpoke":
			pass
	
		"poke":
			# let pokemon = this.rememberTeamPreviewPokemon(args[1], args[2]);
			# if (args[3] === 'mail') {
			# 	pokemon.item = '(mail)';
			# } else if (args[3] === 'item') {
			# 	pokemon.item = '(exists)';
			# }
			var pokemon: Pokemon = remember_team_preview_pokemon(args[1], args[2])
			if args[3] == "mail":
				pokemon.item = "(mail)"
			elif args[3] == "item":
				pokemon.item = "(exists)"

		"updatepoke":
			pass
		"teampreview":
			pass
		"showteam":
			pass
	#endregion
		"switch", "drag", "replace":
			end_last_turn()
			var poke: Pokemon = get_switched_pokemon(args[1], args[2])
			var slot := poke.slot
			poke.health_parse(args[3])
			poke.remove_volatile("itemremoved")

			var tera_match := RegEx.create_from_string("tera:([a-z]+)$").search(args[2].to_lower())
			poke.terastallized = tera_match.get_string(1) if tera_match else ""

			if args[0] == "switch":
				if poke.side.active[slot] != null:
					poke.side.switch_out(poke.side.active[slot], kw_args)
				poke.side.switch_in(poke, kw_args)
			elif args[0] == "replace":
				poke.side.replace(poke)
			else:
				poke.side.drag_in(poke)

			update_weather()
			# log(args, kw_args)
		"faint":
			pass
		"swap":
			pass
		"move":
			pass
		"cant":
			pass
		"gen":
			pass
		"callback":
			pass
		"fieldhtml":
			pass
		"controlshtml":
			pass
		"custom":
			pass
		_:
			pass


func start(player_name: String, packed_team: String) -> void:
	pbattlepeer = PBattlePeer.new()
	thread = Thread.new()
	thread.start(pbattlepeer.prepare.bind(player_name, packed_team))


func present() -> void:
	p1 = Side.new(self, 0)
	p2 = Side.new(self, 1)
	sides = [p1, p2]
	p2.foe = p1
	p1.foe = p2
	my_side = p1
	near_side = my_side
	far_side = p2

	# bind_choices(pbattlepeer.send)

	# $Path2D/PathFollow2D.progress_ratio = 1.0
	# $Path2D2/PathFollow2D.progress_ratio = 1.0

	show()
	camera.enabled = true
	camera.make_current()

	# get_tree().call_group("databoxes", "hide")

func add_pokemon_sprite(pokemon: Pokemon) -> PokemonSprite:
	# const sprite = new PokemonSprite(Dex.getSpriteData(pokemon, pokemon.side.isFar, {
	# 		gen: this.gen,
	# 		mod: this.mod,
	# 	}), {
	# 		x: pokemon.side.x,
	# 		y: pokemon.side.y,
	# 		z: pokemon.side.z,
	# 		opacity: 0,
	# 	}, this, pokemon.side.isFar);
	# 	if (sprite.$el) this.$sprites[+pokemon.side.isFar].append(sprite.$el);
	# 	return sprite;
	return PokemonSprite.new("pikachu", pokemon.side.is_far, sprites[int(pokemon.side.is_far)])


func parse_battle_line(line: String) -> ParsedBattleLine:
	var result := ParsedBattleLine.new()

	# NOTA: Protocol.parseLine(line, true) del original hace un parseo especial
	# para ciertos tipos de línea (chat, raw html, etc). Si tienes esa lógica
	# en otro lado, iría aquí antes del fallback. La omito porque no fue provista.
	if line == "|":
		result.args.push_back("done")
		return result

	if line.is_empty() or line[0] != "|":
		# línea inválida según el formato esperado por Showdown
		return result

	# args = line.slice(1).split('|')
	var rest: String = line.substr(1)
	var args: PackedStringArray = rest.split("|")

	# Extraer kwArgs desde el final: mientras el último elemento
	# tenga forma "[clave]valor"
	while args.size() > 1:
		var last_arg: String = args[args.size() - 1]
		if last_arg.is_empty() or last_arg[0] != "[":
			break

		var bracket_pos: int = last_arg.find("]")
		if bracket_pos <= 0:
			break

		var key: String = last_arg.substr(1, bracket_pos - 1)
		var value_str: String = last_arg.substr(bracket_pos + 1).strip_edges()

		if value_str.is_empty():
			result.kw_args[key] = true # Variant booleano, igual que en el original
		else:
			result.kw_args[key] = value_str

		args.remove_at(args.size() - 1)

	result.args = args
	return result


class ParsedBattleLine:
	var args: PackedStringArray = PackedStringArray()
	var kw_args: Dictionary = { }
