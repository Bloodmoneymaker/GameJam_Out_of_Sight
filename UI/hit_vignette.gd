extends ColorRect

var _pulse: Tween


func pulse() -> void:
	if _pulse != null:
		_pulse.kill()
	modulate.a = 1.0
	_pulse = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pulse.tween_interval(0.06)
	_pulse.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
