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
	draw_colored_polygon(shape, Color(0.18, 0.035, 0.055, 0.95))
	if fill > 0.0:
		var right := 1.0 + 30.0 * fill
		var fill_rect := PackedVector2Array([
			Vector2(0, 0), Vector2(right, 0), Vector2(right, 32), Vector2(0, 32)
		])
		for polygon in Geometry2D.intersect_polygons(shape, fill_rect):
			draw_colored_polygon(polygon, Color(0.95, 0.12, 0.22, 1.0))
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, Color(0.08, 0.015, 0.025, 1.0), 2.0, true)
