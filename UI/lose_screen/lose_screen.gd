extends Control

@onready var exit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ExitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func show_lose_screen() -> void:
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	exit_button.grab_focus()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
