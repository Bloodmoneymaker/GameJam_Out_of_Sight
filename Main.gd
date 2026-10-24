extends Node3D

# Container
@onready var container_scene:Node = $Container/Container_Scene
@onready var container_entity:Node = $Container/Container_Entity
@onready var container_object:Node = $Container/Container_Object

# UI's
@onready var ui_main:Control = $CanvasLayer/UI_Main
@onready var win_screen: Control = $CanvasLayer/WinScreen
@onready var lose_screen: Control = $CanvasLayer/LoseScreen


func _ready() -> void:
	_set_containers()
	_set_ui()
	ui_main.show()
	#AudioManager.play_sound_3d(Audio.SOUND.A,Vector3.ZERO)
	#AudioManager.play_music(Audio.MUSIC.A)

func _set_containers() -> void:
	GameManager.container_scene = container_scene
	GameManager.container_entity = container_entity
	GameManager.container_object = container_object
	

func _set_ui() -> void:
	GameManager.ui_main = ui_main
	GameManager.win_screen = win_screen
	GameManager.lose_screen = lose_screen
