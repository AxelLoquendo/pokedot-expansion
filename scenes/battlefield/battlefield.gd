extends Node2D

signal battle_finished(result: String)

var is_animation_running := false
var packet: String
var step_queue: Array[String]
var pbattlepeer: PBattlePeer
var thread: Thread

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
	if pbattlepeer == null or is_animation_running:
		return

	pbattlepeer.poll()
	var ready_state: int = pbattlepeer.get_ready_state()

	if ready_state == PBattlePeer.STATE_OPEN:
		if pbattlepeer.get_available_packet_count():
			packet = pbattlepeer.get_packet()
			is_animation_running = true
			await handle_action(packet)
			is_animation_running = false


func _exit_tree() -> void:
	thread.wait_to_finish()


func start(player_name: String, packed_team: String) -> void:
	pbattlepeer = PBattlePeer.new()
	thread = Thread.new()
	thread.start(pbattlepeer.prepare.bind(player_name, packed_team))


func present() -> void:
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


## Conecta los cuatro botones de movimiento al callback indicado.
func bind_choices(callback: Callable) -> void:
	fight_move1.pressed.connect(callback.bind("move 1"))
	fight_move2.pressed.connect(callback.bind("move 2"))
	fight_move3.pressed.connect(callback.bind("move 3"))
	fight_move4.pressed.connect(callback.bind("move 4"))


## Actualiza los textos de los botones de movimiento y muestra el panel de lucha.
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


## Anima la barra de HP hacia el nuevo valor de forma progresiva.
func take_damage(position: String, damage: int) -> void:
	const FACTOR_MILISECONDS_PER_POINTS: float = 0.006
	var hp_bar: TextureProgressBar = player_hp_bar if position == "p1a" else foe_hp_bar
	var duration: float = abs(hp_bar.value - damage) * FACTOR_MILISECONDS_PER_POINTS

	var tw: Tween = create_tween()
	tw.tween_property(hp_bar, "value", damage, duration) \
			.set_ease(Tween.EASE_OUT) \
			.set_delay(0.3)
	await tw.finished


## Muestra un mensaje con efecto de escritura y lo oculta al terminar.
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
