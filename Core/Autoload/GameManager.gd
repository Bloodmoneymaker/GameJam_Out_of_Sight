# GameManager.gd (Autoload)
extends Node

enum SCENE {DEBUG,XXX,LEVEL1,SEWER}

# Scene
var container_scene:Node
var container_entity:Node
var container_object:Node
var container_projectiles:Node
#UI
var ui_main
var win_screen: Control
var lose_screen: Control

var scene:Dictionary = {
	SCENE.DEBUG : preload("res://Scene/scene_debug.tscn"),
	SCENE.XXX : preload("res://Scene/scene_test.tscn"),
	SCENE.LEVEL1 : preload("res://Scene/scene_level_1.tscn"),
	SCENE.SEWER : preload("res://Scene/Game_Scene/Scene_Sewer.tscn"),
}

func load_scene(scene_idx:SCENE) -> void:
	var new_scene = scene[scene_idx].instantiate()
	container_scene.add_child(new_scene)

func delete_all_scenes() -> void:
	for child in container_scene.get_children():
		child.queue_free()

func show_win_screen() -> void:
	if is_instance_valid(lose_screen) and lose_screen.visible:
		return
	if is_instance_valid(win_screen):
		win_screen.show_win_screen()


func show_lose_screen() -> void:
	if is_instance_valid(win_screen) and win_screen.visible:
		return
	if is_instance_valid(lose_screen):
		lose_screen.show_lose_screen()
