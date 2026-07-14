extends CanvasLayer

@onready var pause_menu: NinePatchRect = $PauseMenu
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var songs = {
	"menu_close": preload("res://sfx/se/GUI menu close.ogg"),
	"menu_open": preload("res://sfx/se/GUI menu open.ogg"),
}

func _ready() -> void:
	pause_menu.hide()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			pause_menu.visible = !pause_menu.visible
			
			var sfx_name = "menu_open" if pause_menu.visible else "menu_close"
			sfx_player.stream = songs[sfx_name]
			
			sfx_player.play()
