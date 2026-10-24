extends Label

var elapsed_time: float = 0.0
var running: bool = true

func _ready() -> void:
	elapsed_time = 0.0

func _process(delta: float) -> void:
	if running:
		elapsed_time += delta

	var total_seconds := int(elapsed_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	text = "%02d:%02d" % [minutes, seconds]
	GameManager.levelTime = elapsed_time
