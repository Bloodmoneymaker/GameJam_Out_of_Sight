extends Control

@onready var return_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	return_button.pressed.connect(_on_return_button_pressed)


func show_win_screen() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_button.grab_focus()


func _on_return_button_pressed() -> void:
	GameManager.return_to_main_menu()
