extends NinePatchRect

const FRAMES_PER_CHAR = 2 # speed = medium
const FRAMES_PER_SECOND = 60.0

var writing := false
var tween: Tween

@onready var rich_text_label: RichTextLabel = $RichTextLabel


func _gui_input(event):
	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		if not writing:
			hide()
			accept_event()
		else:
			tween.kill()
			rich_text_label.visible_ratio = 1.0
			# evitar saltar el mensaje accidentalmente
			await get_tree().create_timer(0.2).timeout
			writing = false
		accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				grab_focus()


func speech(message: String) -> void:
	show()
	writing = true
	rich_text_label.text = message
	tween = create_tween()
	var message_len = message.length()
	var duration = message_len / FRAMES_PER_SECOND * FRAMES_PER_CHAR
	tween.tween_property(rich_text_label, "visible_characters", message_len, duration)

	tween.finished.connect(_terminate)


func _terminate() -> void:
	writing = false
