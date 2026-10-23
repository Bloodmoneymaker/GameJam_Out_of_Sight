extends Control

@onready var return_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ReturnButton
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	return_button.pressed.connect(_on_return_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	return_button.mouse_entered.connect(_play_hover_sound)
	return_button.focus_entered.connect(_play_hover_sound)
	retry_button.mouse_entered.connect(_play_hover_sound)
	retry_button.focus_entered.connect(_play_hover_sound)


func show_lose_screen() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.grab_focus()


func _on_return_button_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.return_to_main_menu()


func _on_retry_button_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.retry_current_scene()


func _play_hover_sound() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Hover)
