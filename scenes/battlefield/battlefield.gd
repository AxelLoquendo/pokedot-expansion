extends Node2D

var is_animation_running := false
var pbattlepeer = PBattlePeer.new()
var packet: String

@onready var moveset_container: GridContainer = $UI/ColorRect/TextureRect/GridContainer
@onready var player_pokemon: Sprite2D = $Pikachu
@onready var foe_pokemon: Sprite2D = $Pidgey
@onready var player_label: Label = $UI/PlayerPanel/Label
@onready var foe_label: Label = $UI/FoePanel/Label
@onready var player_hp_bar: TextureProgressBar = $UI/PlayerPanel/TextureProgressBar
@onready var foe_hp_bar: TextureProgressBar = $UI/FoePanel/TextureProgressBar
@onready var ui: CanvasLayer = $UI
@onready var move_button_1: TextureButton = $UI/ColorRect/TextureRect/GridContainer/TextureButton
@onready var move_button_2: TextureButton = $UI/ColorRect/TextureRect/GridContainer/TextureButton2
@onready var move_button_3: TextureButton = $UI/ColorRect/TextureRect/GridContainer/TextureButton3
@onready var move_button_4: TextureButton = $UI/ColorRect/TextureRect/GridContainer/TextureButton4
@onready var message_container: Control = $UI/Message
@onready var message_label: RichTextLabel = $UI/Message/RichTextLabel
@onready var ability_bar: Control = $UI/AbilityBar
@onready var ability_label: Label = $UI/AbilityBar/Label


func _ready() -> void:
	bind_choices(pbattlepeer.send)
	pbattlepeer.start("nerfis", "Arcanine||Leftovers|Intimidate|Flareblitz,Extremespeed,Wildcharge,Morningsun|Impish|252,0,252,0,4,0||||||||")


func _physics_process(delta: float) -> void:
	if is_animation_running:
		return

	pbattlepeer.poll()
	var ready_state = pbattlepeer.get_ready_state()

	if ready_state == PBattlePeer.STATE_OPEN:
		if pbattlepeer.get_available_packet_count():
			packet = pbattlepeer.get_packet()
			is_animation_running = true
			await handle_action(packet)
			is_animation_running = false


func present() -> void:
	show()
	ui.show()


func bind_choices(callback: Callable) -> void:
	move_button_1.connect("pressed", callback.bind("move 1"))
	move_button_2.connect("pressed", callback.bind("move 2"))
	move_button_3.connect("pressed", callback.bind("move 3"))
	move_button_4.connect("pressed", callback.bind("move 4"))


func display_moveset(moveset: Array) -> void:
	for i in range(moveset.size()):
		moveset_container.get_child(i).get_child(0).text = moveset[i]
	show_options()


func show_options() -> void:
	moveset_container.show()
	move_button_1.grab_focus()


func hide_options() -> void:
	moveset_container.hide()


func take_damage(position: String, damage: int) -> void:
	var tw = create_tween()
	var hp_bar = player_hp_bar if position == "p1a" else foe_hp_bar
	const FACTOR_MILISECONDS_PER_POINTS = 0.006
	var duration = abs(hp_bar.value - damage) * FACTOR_MILISECONDS_PER_POINTS
	tw.tween_property(hp_bar, "value", damage, duration).set_ease(Tween.EASE_OUT)

	await tw.finished


func message(msg: String) -> void:
	message_label.visible_ratio = 0
	message_label.text = msg

	message_container.show()
	var tw = create_tween()
	const SECONDS_PER_CHAR: float = 1.0 / 15
	tw.tween_property(message_label, "visible_ratio", 1, msg.length() * SECONDS_PER_CHAR)
	await tw.finished
	await get_tree().create_timer(1).timeout
	message_container.hide()


func splash(pokemon: String, ability: String) -> void:
	#$AbilityBar/Pokemon.text = pokemon
	ability_label.text = ability

	var tw = create_tween()
	tw.tween_property(ability_bar, "position:x", 260, 0.8)
	tw.tween_property(ability_bar, "position:x", 260, 1)
	tw.tween_property(ability_bar, "position:x", 520, 0.4)
	await tw.finished


func animate(func_str: String, argv: Array) -> void:
	await callv(func_str, argv)
	emit_signal("animation_completed", null)


func switch(ident: String, max_hp: int, hp: int) -> void:
	var sprite2d = player_pokemon if ident.begins_with("p1a") else foe_pokemon
	var label = player_label if ident.begins_with("p1a") else foe_label
	var hp_bar = player_hp_bar if ident.begins_with("p1a") else foe_hp_bar

	# Incluir el manejo de pokemon con variantes

	var pokemon = ident.substr(5).replace("-", "").replace(" ", "")
	var pokemon_id = pokemon.to_lower()

	player_hp_bar.set_max(max_hp)
	player_hp_bar.set_value(hp)
	label.text = pokemon
	sprite2d.texture = load("res://graphics/pokemon/front/%s.png" % pokemon_id)


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
	var parsed := parse_battle_line(action)
	var args := parsed.args
	var kw_args := parsed.kw_args

	match args[0]:
		"request":
			var request_payload = JSON.parse_string(action.substr(9))
			var active = request_payload.get("active")

			if active == null:
				return

			var moves: Array = active[0]["moves"]

			var moveset: Array = []
			for move in moves:
				moveset.push_back(String(move["move"]))

			display_moveset(moveset)
		"-damage":
			assert(args.size() >= 3, "Los args del action -damage deben tener al menos una longitud de 3")

			var ident: String = args[1] # "p1a: Bulbasaur"
			var position: String = ident.substr(0, 3)

			if args[2].ends_with("fnt"):
				await take_damage(position, 0)
				return

			var hp_diff: PackedStringArray = args[2].split("/")

			var hp_max: int = hp_diff[1].to_int()
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
		"faint":
			var position: String = args[1].substr(0, 3)
			await take_damage(position, 0)
			await message("%s has fainted!\n" % args[1].substr(5))
		"error":
			if kw_args.has("Invalid choice"):
				show_options()
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
			var stages: String = args[3]

			await message("%s's %s fell!" % [pokemon, stat])
		"-boost":
			assert(args.size() >= 4, "Los args del action -boost deben tener al menos una longitud de 4")

			var pokemon: String = args[1].substr(5) # quitar "p1a: "
			var stat: String = args[2]
			var stages: String = args[3]

			await message("%s's %s rose!" % [pokemon, stat])
		"-activate":
			assert(args.size() >= 3, "Los args del action -activate deben tener al menos una longitud de 3")

			var pokemon: String = args[1].substr(5)
			var effect: String = args[2] # "move: Protect"

			if effect.begins_with("move:"):
				var move_name: String = effect.substr(5).strip_edges()
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
