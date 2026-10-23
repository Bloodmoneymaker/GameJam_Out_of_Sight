class_name HealthComponent
extends Node
## Reusable health storage; the owner decides what happens on death.

signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
var current_health: float = 0.0
var _dead := false


func _ready() -> void:
	current_health = maxf(max_health, 1.0)
	health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	var just_died := current_health <= 0.0
	_dead = just_died
	health_changed.emit(current_health, max_health)
	if just_died:
		died.emit()


func is_dead() -> bool:
	return _dead
