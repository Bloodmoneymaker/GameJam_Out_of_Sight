# GameManager.gd (Autoload)
extends Node

enum SCENE {DEBUG,XXX}

# Scene
var container_scene:Node
var container_entity:Node
var container_object:Node
var container_projectiles:Node
#UI
var ui_main
var win_screen: Control

var scene:Dictionary = {
	SCENE.DEBUG : preload("res://Scene/scene_debug.tscn"),
	SCENE.XXX : preload("res://Scene/scene_test.tscn")
}

func load_scene(scene_idx:SCENE) -> void:
	var new_scene = scene[scene_idx].instantiate()
	container_scene.add_child(new_scene)

func delete_all_scenes() -> void:
	for child in container_scene.get_children():
		child.queue_free()

func show_win_screen() -> void:
	if is_instance_valid(win_screen):
		win_screen.show_win_screen()
