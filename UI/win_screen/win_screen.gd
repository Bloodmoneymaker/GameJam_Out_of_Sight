extends Control

@onready var return_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ReturnButton
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	return_button.pressed.connect(_on_return_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)


func show_win_screen() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.grab_focus()


func _on_return_button_pressed() -> void:
	GameManager.return_to_main_menu()


func _on_retry_button_pressed() -> void:
	GameManager.retry_current_scene()
