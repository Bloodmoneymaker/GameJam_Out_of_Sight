extends Node3D



# Container
@onready var container_scene:Node = $Container/Container_Scene
@onready var container_entity:Node = $Container/Container_Entity

# UI's
@onready var ui_main:Control = $CanvasLayer/UI_Main


func _ready() -> void:
	_set_containers()
	_set_ui()
	GameManager.load_scene(GameManager.SCENE.DEBUG)
	#AudioManager.play_sound_3d(Audio.SOUND.A,Vector3.ZERO)
	#AudioManager.play_music(Audio.MUSIC.A)

func _set_containers() -> void:
	GameManager.container_scene = container_scene
	GameManager.container_entity = container_entity
	

func _set_ui() -> void:
	GameManager.ui_main = ui_main
