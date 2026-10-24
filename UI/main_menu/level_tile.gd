class_name LevelTile
extends Button

@export var level_id: int = 0
@export_range(1, 99, 1) var display_number: int = 1

@onready var number_label: Label = $Content/Number
@onready var title_label: Label = $Content/Title


func _ready() -> void:
	_connect_level_selection()
	_update_labels()
		


func _connect_level_selection() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func _update_labels() -> void:
	number_label.text = "%02d" % display_number
	title_label.text = GameManager.get_scene_title(level_id).to_upper()


func _on_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.load_scene(level_id)

func _play_hover_sound() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Hover)


func _on_focus_entered() -> void:
	if !disabled:
		_play_hover_sound()

func _on_mouse_entered() -> void:
	if !disabled:
		_play_hover_sound()
