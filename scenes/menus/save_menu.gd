extends PMenu

@onready var yes_button: Button = $Confirm/VBoxContainer/Yes
@onready var no_button: Button = $Confirm/VBoxContainer/No


func _focus():
	$Confirm/VBoxContainer/Yes.grab_focus()

func _on_yes_pressed() -> void:
	hide()


func _on_no_pressed() -> void:
	hide()
