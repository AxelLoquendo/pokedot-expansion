extends CanvasLayer

const songs = {
	"menu_close": preload("res://sfx/se/GUI menu close.ogg"),
	"menu_open": preload("res://sfx/se/GUI menu open.ogg"),
}

@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var pause_menu: NinePatchRect = $PauseMenu
@onready var speech: NinePatchRect = $Speech


func _ready() -> void:
	pause_menu.hide()
	speech.hide()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			pause_menu.visible = !pause_menu.visible

			var sfx_name = "menu_open" if pause_menu.visible else "menu_close"
			sfx_player.stream = songs[sfx_name]

			sfx_player.play()
