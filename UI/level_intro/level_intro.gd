extends Control

@onready var level_label: Label = $CenterContainer/PanelContainer/LevelLabel

var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func show_level(level_name: String) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	level_label.text = "LEVEL: %s" % level_name.to_upper()
	modulate.a = 1.0
	show()
	_fade_tween = create_tween()
	_fade_tween.tween_interval(1.4)
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.8)
	_fade_tween.tween_callback(hide)
