# GameManager.gd (Autoload)
extends Node

enum SCENE {DEBUG,TUTORIAL_1,TUTORIAL_2,LEVEL1,SEWER}

# Scene
var container_scene:Node
var container_entity:Node
var container_object:Node
var container_projectiles:Node
#UI
var ui_main
var win_screen: Control
var lose_screen: Control

## Paths are loaded only after a menu tile is selected. Preloading a level that
## references autoloads can create a resource-loading cycle during startup.
var scene: Dictionary = {
	SCENE.TUTORIAL_1: "res://Scene/tutorial_1.tscn",
	SCENE.TUTORIAL_2: "res://Scene/tutorial_2.tscn",
	SCENE.LEVEL1: "res://Scene/scene_level_1.tscn",
	SCENE.SEWER: "res://Scene/Game_Scene/Scene_Sewer.tscn",
	SCENE.DEBUG: "res://Scene/scene_debug.tscn",
}

var scene_titles: Dictionary = {
	SCENE.DEBUG: "Level Monster",
	SCENE.TUTORIAL_1: "Tutorial 1",
	SCENE.TUTORIAL_2: "Tutorial 2",
	SCENE.LEVEL1: "Level 1",
	SCENE.SEWER: "Sewer",
}

func load_scene(scene_idx: SCENE) -> void:
	if not scene.has(scene_idx):
		push_error("Unknown scene id: %s" % scene_idx)
		return

	var packed_scene := load(scene[scene_idx]) as PackedScene
	if packed_scene == null:
		push_error("Could not load scene: %s" % scene[scene_idx])
		return

	delete_all_scenes()
	var new_scene := packed_scene.instantiate()
	container_scene.add_child(new_scene)
	if is_instance_valid(ui_main):
		ui_main.hide()
	if is_instance_valid(win_screen):
		win_screen.hide()
	if is_instance_valid(lose_screen):
		lose_screen.hide()
	get_tree().paused = false


func return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	delete_all_scenes()
	if is_instance_valid(win_screen):
		win_screen.hide()
	if is_instance_valid(lose_screen):
		lose_screen.hide()
	if is_instance_valid(ui_main):
		ui_main.show()


func get_scene_title(scene_idx: int) -> String:
	return str(scene_titles.get(scene_idx, "Level %d" % scene_idx))

func delete_all_scenes() -> void:
	for container in [container_scene, container_entity, container_object, container_projectiles]:
		if not is_instance_valid(container):
			continue
		for child in container.get_children():
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
