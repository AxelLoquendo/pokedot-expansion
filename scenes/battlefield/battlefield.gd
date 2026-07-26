class_name Battle
extends Node2D

signal battle_finished(result: String)

var is_animation_running := false
var packet: String
var at_queue_end := true
var ended := false
var step_queue: Array[String]
var log: Array[Array]
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

# ── Pokémon sprites ────────────────────────────────────────────────────────────
@onready var player_pokemon: Sprite2D = $Base/Pokemon
@onready var foe_pokemon: Sprite2D = $BaseFoe/PokemonFoe
@onready var player_base: Sprite2D = $Base
@onready var foe_base: Sprite2D = $BaseFoe
# ── Cajas de datos (DataBox = jugador, DataBoxFoe = rival) ────────────────────
@onready var player_label: Label = $UI/DataBox/Label
@onready var foe_label: Label = $UI/DataBoxFoe/Label
@onready var player_hp_bar: TextureProgressBar = $UI/DataBox/TextureProgressBar
@onready var foe_hp_bar: TextureProgressBar = $UI/DataBoxFoe/TextureProgressBar
# ── UI principal ───────────────────────────────────────────────────────────────
@onready var ui: Control = $UI
# ── Panel de habilidad ─────────────────────────────────────────────────────────
@onready var ability_bar: TextureRect = $UI/AbilityBar
@onready var ability_label: Label = $UI/AbilityBar/Label
# ── Panel de movimientos ───────────────────────────────────────────────────────
@onready var fight_overlay: ColorRect = %Move
@onready var fight_move1: TextureButton = %Move1
@onready var fight_move2: TextureButton = %Move2
@onready var fight_move3: TextureButton = %Move3
@onready var fight_move4: TextureButton = %Move4
# ── Menú de acción (Luchar / Bolsa / Pokémon / Huir) ─────────────────────────
@onready var command_overlay: ColorRect = %Command
@onready var command_fight: TextureButton = %Fight
# ── Panel de mensajes ──────────────────────────────────────────────────────────
@onready var message_overlay: ColorRect = %Message
@onready var message_label: RichTextLabel = %Message/RichTextLabel
# ── Cámara ─────────────────────────────────────────────────────────────────────
@onready var camera: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	command_fight.pressed.connect(func(): fight_overlay.show())

	message_overlay.hide()
	fight_overlay.hide()
	command_overlay.hide()

	$Path2D/PathFollow2D.progress_ratio = 1.0
	$Path2D2/PathFollow2D.progress_ratio = 1.0


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


func _start() -> void:
	log.push_back(["start"])
	reset_turns_since_moved()


func reset_turns_since_moved() -> void:
	turns_since_moved = 0;


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


func run_major(args: PackedStringArray, kw_args: Dictionary) -> void:
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
			print("el pokemon se ha cargado con exito")
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
		"switch", "drag", "replace":
			pass
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

	bind_choices(pbattlepeer.send)

	$Path2D/PathFollow2D.progress_ratio = 1.0
	$Path2D2/PathFollow2D.progress_ratio = 1.0

	show()
	camera.enabled = true
	camera.make_current()

	get_tree().call_group("databoxes", "hide")


func dispose() -> void:
	hide()
	camera.enabled = false


func bind_choices(callback: Callable) -> void:
	fight_move1.pressed.connect(callback.bind("move 1"))
	fight_move2.pressed.connect(callback.bind("move 2"))
	fight_move3.pressed.connect(callback.bind("move 3"))
	fight_move4.pressed.connect(callback.bind("move 4"))


func add_pokemon_sprite(pokemon: Pokemon) -> Sprite2D:
	# TODO: deberia retornar un sprite2D que se encuentre instanciado en la escena
	return Sprite2D.new()

func display_command(moveset: Array) -> void:
	var moveset_container = fight_move1.get_parent()

	for i in range(moveset.size()):
		moveset_container.get_child(i).get_child(0).text = moveset[i]

	command_overlay.show()
	fight_overlay.hide()
	message_overlay.hide()


func show_commands() -> void:
	command_overlay.show()
	fight_overlay.hide()
	message_overlay.hide()


func take_damage(position: String, damage: int) -> void:
	const FACTOR_MILISECONDS_PER_POINTS: float = 0.006
	var hp_bar: TextureProgressBar = player_hp_bar if position == "p1a" else foe_hp_bar
	var duration: float = abs(hp_bar.value - damage) * FACTOR_MILISECONDS_PER_POINTS

	var tw: Tween = create_tween()
	tw.tween_property(hp_bar, "value", damage, duration) \
			.set_ease(Tween.EASE_OUT) \
			.set_delay(0.3)
	await tw.finished


func message(msg: String) -> void:
	message_label.visible_ratio = 0.0
	message_label.text = msg
	message_overlay.show()

	const SECONDS_PER_CHAR: float = 1.0 / 20.0
	var tw: Tween = create_tween()
	tw.tween_property(message_label, "visible_ratio", 1.0, msg.length() * SECONDS_PER_CHAR)
	await tw.finished
	await get_tree().create_timer(1.0).timeout


## Desliza la barra de habilidad desde fuera de la pantalla hacia adentro y la oculta.
func splash(_pokemon: String, ability: String) -> void:
	ability_label.text = ability

	var tw: Tween = create_tween()
	tw.tween_property(ability_bar, "position:x", 260.0, 0.8)
	tw.tween_property(ability_bar, "position:x", 260.0, 1.0)
	tw.tween_property(ability_bar, "position:x", 520.0, 0.4)
	await tw.finished


## Cambia el sprite, la barra de HP y la etiqueta del Pokémon activo.
func switch(ident: String, max_hp: int, hp: int) -> void:
	var is_player: bool = ident.begins_with("p1a")
	var sprite: Sprite2D = player_pokemon if is_player else foe_pokemon
	var label: Label = player_label if is_player else foe_label
	var hp_bar: TextureProgressBar = player_hp_bar if is_player else foe_hp_bar

	# Incluir el manejo de pokemon con variantes
	var pokemon: String = ident.substr(5).replace("-", "").replace(" ", "")
	var pokemon_id: String = pokemon.to_lower()

	hp_bar.max_value = max_hp
	hp_bar.value = hp
	label.text = pokemon

	var face: String = "back" if is_player else "front"
	sprite.texture = load("res://graphics/pokemon/%s/%s.png" % [face, pokemon_id])

	if not is_player:
		animation_player.play("intro")
		get_tree().call_group("databoxes", "show")


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


func handle_action(action: String) -> void:
	var parsed: ParsedBattleLine = parse_battle_line(action)
	var args: PackedStringArray = parsed.args
	var kw_args: Dictionary = parsed.kw_args

	match args[0]:
		"request":
			var request_payload: Dictionary = JSON.parse_string(action.substr(9))
			var active: Variant = request_payload.get("active")

			if active == null:
				return

			var moves: Array = active[0]["moves"]
			var moveset: Array = []
			for move: Dictionary in moves:
				moveset.push_back(String(move["move"]))

			display_command(moveset)
		"-damage":
			assert(args.size() >= 3, "Los args del action -damage deben tener al menos una longitud de 3")

			var ident: String = args[1] # "p1a: Bulbasaur"
			var position: String = ident.substr(0, 3)

			if args[2].ends_with("fnt"):
				await take_damage(position, 0)
				return

			var hp_diff: PackedStringArray = args[2].split("/")
			var hp: int = hp_diff[0].to_int()
			await take_damage(position, hp)

			if kw_args.has("from"):
				var from: String = kw_args["from"]
				if from == "Recoil":
					await message("%s has taken recoil damage" % ident.substr(5))
		"-heal":
			assert(args.size() >= 3, "Los args del action -heal deben tener al menos una longitud de 3")

			var ident: String = args[1]
			var position: String = ident.substr(0, 3)

			var hp_diff: PackedStringArray = args[2].split("/")
			var hp: int = hp_diff[0].to_int()
			await take_damage(position, hp)

			if kw_args.has("from"):
				var from: String = kw_args["from"]
				# ej: "item: Leftovers" → extraer el nombre del objeto
				if from.begins_with("item:"):
					var item_name: String = from.substr(5).strip_edges()
					await message("%s restored HP with its %s!" % [ident.substr(5), item_name])
		"switch": # |switch|p1a: Arbok|Arbok, L78, M|254/254
			assert(args.size() >= 4, "Los args del actions switch deben tener al menos una longitud de 4")

			var ident: String = args[1] # p1a: Growlithe
			var hp_diff: PackedStringArray = args[3].split("/")
			var max_hp: int = hp_diff[1].to_int()
			var hp: int = hp_diff[0].to_int()
			switch(ident, max_hp, hp)
		"win":
			await message("%s win!\n" % args[1])
			battle_finished.emit("win")
		"faint":
			var position: String = args[1].substr(0, 3)
			await take_damage(position, 0)
			await message("%s has fainted!\n" % args[1].substr(5))
		"error":
			if kw_args.has("Invalid choice"):
				show_commands()
		"move":
			var ident: String = args[1]
			var move: String = args[2]
			await message("%s has used \n%s" % [ident, move])
		"-ability":
			var ident: String = args[1]
			var pokemon: String = ident.substr(5)
			var ability: String = args[2]
			await splash(pokemon, ability)
		"-resisted":
			await message("It's not very effective...")
		"-supereffective":
			await message("It's very effective...")
		"-unboost":
			assert(args.size() >= 4, "Los args del action -unboost deben tener al menos una longitud de 4")
			var pokemon: String = args[1].substr(5) # quitar "p1a: "
			var stat: String = args[2]
			await message("%s's %s fell!" % [pokemon, stat])
		"-boost":
			assert(args.size() >= 4, "Los args del action -boost deben tener al menos una longitud de 4")
			var pokemon: String = args[1].substr(5) # quitar "p1a: "
			var stat: String = args[2]
			await message("%s's %s rose!" % [pokemon, stat])
		"-activate":
			assert(args.size() >= 3, "Los args del action -activate deben tener al menos una longitud de 3")
			var pokemon: String = args[1].substr(5)
			var effect: String = args[2] # "move: Protect"
			if effect.begins_with("move:"):
				await message("%s protected itself!" % pokemon)
		"-fail":
			assert(args.size() >= 2, "Los args del action -fail deben tener al menos una longitud de 2")
			var pokemon: String = args[1].substr(5)
			if kw_args.has("from"):
				var from: String = kw_args["from"]
				# ej: "ability: Own Tempo"
				if from.begins_with("ability:"):
					var ability_name: String = from.substr(8).strip_edges()
					await message("%s's %s prevents that!" % [pokemon, ability_name])
			else:
				await message("But it failed for %s!" % pokemon)
		"poke", "teampreview", "teamsize", "t:", "upkeep", "done":
			# Acciones de metadata/setup que no requieren animación
			return


class ParsedBattleLine:
	var args: PackedStringArray = PackedStringArray()
	var kw_args: Dictionary = { }
