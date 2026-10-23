extends Control

@onready var return_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	return_button.pressed.connect(_on_return_button_pressed)


func show_lose_screen() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_button.grab_focus()


func _on_return_button_pressed() -> void:
	GameManager.return_to_main_menu()
