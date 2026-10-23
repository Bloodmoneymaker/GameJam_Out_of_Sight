@tool
extends Control

var fill: float = 1.0

func set_fill(value: float) -> void:
	fill = clampf(value, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var shape := PackedVector2Array([
		Vector2(16, 8), Vector2(12, 4), Vector2(7, 3), Vector2(3, 5),
		Vector2(1, 9), Vector2(1, 13), Vector2(4, 18), Vector2(16, 29),
		Vector2(28, 18), Vector2(31, 13), Vector2(31, 9), Vector2(29, 5),
		Vector2(25, 3), Vector2(20, 4),
	])
	var outline := shape.duplicate()
	outline.append(shape[0])
	var dim_color := Color(0.1, 0.24, 0.28, 0.85)
	var health_color := Color(0.2, 0.84, 0.9, 1.0)
	var outline_color := dim_color.lerp(health_color, fill)
	if fill > 0.0:
		var glow_color := health_color
		glow_color.a = 0.18 * fill
		draw_polyline(outline, glow_color, 5.0, true)
	draw_polyline(outline, outline_color, 2.0, true)
