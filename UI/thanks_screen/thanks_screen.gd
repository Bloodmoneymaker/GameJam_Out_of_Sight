extends Control

@onready var return_button: Button = $CenterContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	return_button.pressed.connect(_on_return_button_pressed)
	return_button.mouse_entered.connect(_play_hover_sound)
	return_button.focus_entered.connect(_play_hover_sound)


func show_thanks_screen() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_button.grab_focus()


func _on_return_button_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.return_to_main_menu()


func _play_hover_sound() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Hover)
