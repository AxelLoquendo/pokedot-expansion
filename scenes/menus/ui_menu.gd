class_name PMenu
extends Control

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				_focus()
				get_tree().call_group("npcs", "set_physics_process", false)
				get_tree().call_group("player", "set_physics_process", false)
			else:
				get_tree().call_group("npcs", "set_physics_process", true)
				get_tree().call_group("player", "set_physics_process", true)

func _focus():
	grab_focus()
