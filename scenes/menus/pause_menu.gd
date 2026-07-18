extends PMenu

const SONGS = {
	"menu_close": preload("res://sfx/se/GUI menu close.ogg"),
	"menu_open": preload("res://sfx/se/GUI menu open.ogg"),
}

@onready var sfx_player: AudioStreamPlayer = $"../SfxPlayer"

@export var save_menu: Control

func _focus():
	$VBoxContainer/Button.grab_focus()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			visible = !visible

			var sfx_name = "menu_open" if visible else "menu_close"
			sfx_player.stream = SONGS[sfx_name]
			
			sfx_player.play()
			
			get_viewport().set_input_as_handled()


func _on_button_4_pressed() -> void:
	hide()
	save_menu.show()
