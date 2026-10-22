extends Control

const CHARGE_SLOT: PackedScene = preload("res://UI/echoCharge/chargeSlot.tscn")

@export var charger: Node
@export_range(0.05, 0.5, 0.01) var blink_interval: float = 0.1

@onready var bars: HBoxContainer = $Margin/Charges

var _current := 0
var _maximum := 0
var _animations: Dictionary = {}


func _ready() -> void:
	if not is_instance_valid(charger):
		return
	charger.charges_changed.connect(_on_charges_changed)
	_set_initial_charges(charger.current_charges, charger.max_charges)


func _set_initial_charges(current: int, maximum: int) -> void:
	for animation in _animations.values():
		animation.kill()
	_animations.clear()
	for child in bars.get_children():
		bars.remove_child(child)
		child.queue_free()
	for index in range(maximum):
		var slot := CHARGE_SLOT.instantiate()
		slot.name = "Charge%d" % (index + 1)
		bars.add_child(slot)
		var fill: Control = slot.get_node("Fill")
		fill.modulate.a = 1.0 if index < current else 0.0
	_current = current
	_maximum = maximum


func _on_charges_changed(current: int, maximum: int) -> void:
	current = clampi(current, 0, maximum)
	if maximum != _maximum:
		_set_initial_charges(current, maximum)
		return
	for index in range(maximum):
		if (index < current) != (index < _current):
			_blink_charge(index, index < current)
	_current = current


func _blink_charge(index: int, available: bool) -> void:
	if _animations.has(index):
		_animations[index].kill()
	var fill: Control = bars.get_child(index).get_node("Fill")
	var animation := create_tween()
	_animations[index] = animation
	fill.modulate.a = 1.0
	for cycle in range(3):
		animation.tween_property(fill, "modulate:a", 0.0, blink_interval)
		animation.tween_property(fill, "modulate:a", 1.0, blink_interval)
	animation.tween_property(fill, "modulate:a", 1.0 if available else 0.0, blink_interval)
	animation.tween_callback(func(): _animations.erase(index))
