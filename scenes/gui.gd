extends CanvasLayer

signal transition_finished

const TRANSITION_DURATION := 2.0

var _current_tween: Tween

@onready var transition: ColorRect = $Transition


func transition_progress_1() -> Signal:
	return _animate_progress(0.0, 1.0)


func transition_progress_0() -> Signal:
	return _animate_progress(1.0, 0.0)


func _animate_progress(from: float, to: float) -> Signal:
	if _current_tween and _current_tween.is_running():
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.tween_method(_set_transition_progress, from, to, TRANSITION_DURATION)
	_current_tween.finished.connect(func(): transition_finished.emit())

	return _current_tween.finished


func _set_transition_progress(value: float) -> void:
	if transition.material:
		transition.material.set_shader_parameter("progress_trans", value)
