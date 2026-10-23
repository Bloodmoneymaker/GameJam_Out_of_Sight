@tool
extends Control

const HEART_SCENE: PackedScene = preload("res://UI/health_hearts/heart.tscn")

@export var health_component: Node
@export_range(1.0, 1000.0, 1.0) var health_per_heart: float = 1.0

@onready var hearts: HBoxContainer = $Hearts


func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor the player HealthComponent is available for its configured
		# maximum, while current_health is initialized only when the game runs.
		var preview_max := 3.0
		if is_instance_valid(health_component):
			preview_max = float(health_component.get("max_health"))
		_on_health_changed(preview_max, preview_max)
		return

	if not is_instance_valid(health_component):
		return
	health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(health_component.current_health, health_component.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	var count := ceili(maxf(maximum, 0.0) / maxf(health_per_heart, 1.0))
	while hearts.get_child_count() < count:
		var heart := HEART_SCENE.instantiate()
		heart.name = "Heart%d" % (hearts.get_child_count() + 1)
		hearts.add_child(heart)
	while hearts.get_child_count() > count:
		var heart := hearts.get_child(-1)
		hearts.remove_child(heart)
		heart.queue_free()

	for index in range(count):
		var capacity := minf(health_per_heart, maximum - index * health_per_heart)
		var health_in_heart := clampf(current - index * health_per_heart, 0.0, capacity)
		hearts.get_child(index).set_fill(health_in_heart / capacity if capacity > 0.0 else 0.0)
