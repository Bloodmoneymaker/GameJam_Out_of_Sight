class_name Trap
extends Node3D

const TriggerBase = preload("res://Scene/trap/trigger.gd")

signal activated
signal deactivated

@export var trigger: TriggerBase
## Start automatically when no external trigger is assigned.
@export var start_active: bool = false
var is_active := false


func _ready() -> void:
	if is_instance_valid(trigger):
		trigger.triggered.connect(activate)
	elif start_active:
		activate.call_deferred()


func activate() -> void:
	if is_active:
		return
	is_active = true
	_on_activated()
	activated.emit()


func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	_on_deactivated()
	deactivated.emit()


func _on_activated() -> void:
	pass


func _on_deactivated() -> void:
	pass
