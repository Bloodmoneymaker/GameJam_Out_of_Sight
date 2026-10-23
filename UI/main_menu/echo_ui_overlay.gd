extends ColorRect

const ECHO_INTERVAL := 2.0
const MAX_WAVES := 4

@onready var echo_material: ShaderMaterial = material as ShaderMaterial

var _time_until_echo := 0.0
var _elapsed := 0.0
var _next_wave := 0
var _wave_data := PackedVector4Array()


func _ready() -> void:
	_wave_data.resize(MAX_WAVES)
	echo_material.set_shader_parameter("wave_data", _wave_data)
	_update_viewport_size()
	_emit_echo()


func _process(delta: float) -> void:
	_update_viewport_size()
	_elapsed += delta
	echo_material.set_shader_parameter("now", _elapsed)
	_time_until_echo += delta
	if _time_until_echo >= ECHO_INTERVAL:
		_time_until_echo -= ECHO_INTERVAL
		_emit_echo()


func _emit_echo() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var mouse_position := get_global_mouse_position()
	var mouse_uv := mouse_position / viewport_size
	_wave_data[_next_wave] = Vector4(mouse_uv.x, mouse_uv.y, _elapsed, 1.0)
	_next_wave = (_next_wave + 1) % MAX_WAVES
	echo_material.set_shader_parameter("wave_data", _wave_data)


func _update_viewport_size() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		echo_material.set_shader_parameter("viewport_pixel_size", Vector2.ONE / viewport_size)
