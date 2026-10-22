# GameManager.gd (Autoload)
extends Node

enum SCENE {DEBUG,XXX}

# Scene
var container_scene
var container_entity
#UI
var ui_main

var scene:Dictionary = {
	"Debug" : preload("res://Scene/scene_test.tscn"),
	"XXX" : preload("res://Scene/scene_test.tscn")
}

func load_scene(scene_idx:SCENE) -> void:
	print(scene[0])
	#var new_scene = scene[scene_idx].instantiate()
	#container_scene.add_child(new_scene)
