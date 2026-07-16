extends NinePatchRect

@onready var yes_button: Button = $Confirm/VBoxContainer/Yes
@onready var no_button: Button = $Confirm/VBoxContainer/No


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY, NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				$Confirm/VBoxContainer/Yes.grab_focus()
				$"../../Overworld".process_mode = Node.PROCESS_MODE_DISABLED
			else:
				$"../../Overworld".process_mode = Node.PROCESS_MODE_INHERIT


func _on_yes_pressed() -> void:
	hide()


func _on_no_pressed() -> void:
	hide()
