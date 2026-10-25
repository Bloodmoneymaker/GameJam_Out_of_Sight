# GameManager.gd (Autoload)
extends Node

enum SCENE {DEBUG = 0,TUTORIAL_1 = 1,TUTORIAL_2 = 2,SEWER = 4,FOREST = 5,TUTORIAL_3 = 6,Graveyard = 7,CRYPT = 8,NONE = -1}

# Scene
var container_scene:Node
var container_entity:Node
var container_object:Node
#UI
var ui_main
var win_screen: Control
var lose_screen: Control
var current_scene_id: int = -1

var level_times: Dictionary[SCENE, float] = {}
var current_level_time: float = 0.0

## Paths are loaded only after a menu tile is selected. Preloading a level that
## references autoloads can create a resource-loading cycle during startup.
var scene: Dictionary = {
	SCENE.TUTORIAL_1: "res://Scene/tutorial_1.tscn",
	SCENE.TUTORIAL_2: "res://Scene/tutorial_2.tscn",
	SCENE.TUTORIAL_3: "res://Scene/tutorial_3.tscn",
	SCENE.SEWER: "res://Scene/Game_Scene/Scene_Sewer.tscn",
	SCENE.DEBUG: "res://Scene/scene_debug.tscn",
	SCENE.FOREST : "res://Scene/Game_Scene/Scene_Forest.tscn",
	SCENE.Graveyard : "res://Scene/Game_Scene/Scene_Graveyard.tscn",
	SCENE.CRYPT: "res://Scene/Game_Scene/Scene_Crypt.tscn"
}

var scene_titles: Dictionary = {
	SCENE.DEBUG: "Monster",
	SCENE.TUTORIAL_1: "Tutorial 1",
	SCENE.TUTORIAL_2: "Tutorial 2",
	SCENE.TUTORIAL_3: "Tutorial 3",
	SCENE.SEWER: "Sewer",
	SCENE.Graveyard: "Graveyard",
	SCENE.CRYPT: "Crypt",
	SCENE.FOREST: "Forest"
}

var completed_missions: Array[SCENE] = []


func addLevelTime(time: float) -> void:
	var best_time: float = getLevelTime()
	if best_time == -1.0 or time < best_time:
		level_times[get_current_scene()] = time

func getLevelTime() -> float:
	var scene: SCENE = get_current_scene()
	return level_times.get(scene, -1.0)

func get_current_scene() -> SCENE:
	if is_instance_valid(ui_main) and ui_main.visible:
		return SCENE.NONE
	return current_scene_id as SCENE

func load_scene(scene_idx: SCENE) -> void:
	if not scene.has(scene_idx):
		push_error("Unknown scene id: %s" % scene_idx)
		return

	var packed_scene := load(scene[scene_idx]) as PackedScene
	if packed_scene == null:
		push_error("Could not load scene: %s" % scene[scene_idx])
		return

	current_scene_id = scene_idx
	current_level_time = 0.0
	delete_all_scenes()
	var new_scene := packed_scene.instantiate()
	container_scene.add_child(new_scene)
	if is_instance_valid(ui_main):
		ui_main.hide()
	Echo.clear_waves()
	if is_instance_valid(win_screen):
		win_screen.hide()
	if is_instance_valid(lose_screen):
		lose_screen.hide()
	get_tree().paused = false


func retry_current_scene() -> void:
	if current_scene_id < 0:
		push_warning("Cannot retry: no level has been selected yet.")
		return
	load_scene(current_scene_id)


func return_to_main_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	delete_all_scenes()
	Echo.clear_waves()
	if is_instance_valid(win_screen):
		win_screen.hide()
	if is_instance_valid(lose_screen):
		lose_screen.hide()
	if is_instance_valid(ui_main):
		ui_main.show()


func get_scene_title(scene_idx: int) -> String:
	return str(scene_titles.get(scene_idx, "Level %d" % scene_idx))

func delete_all_scenes() -> void:
	for container in [container_scene, container_entity, container_object]:
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
