## SpawnManager.gd (Autoload)
extends Node

enum OBJECT {A,B,C}
enum ENTITY {Player}

var object:Dictionary = {
	OBJECT.A : preload("res://main.tscn")
}
var entity:Dictionary = {
	ENTITY.Player : preload("res://Scene/player/player.tscn")
}

func spawn_object(object_idx:OBJECT) -> void:
	var new_object = object[object_idx].instantiate()
	GameManager.container_object.add_child(new_object)

func spawn_entity(entity_idx:ENTITY) -> void:
	var new_entity = entity[entity_idx].instantiate()
	GameManager.container_entity.add_child(new_entity)
