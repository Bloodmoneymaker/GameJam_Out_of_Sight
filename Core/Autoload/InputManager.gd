## InputManager.gd (Autoload)
extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if not is_instance_valid(GameManager.container_scene):
			return
		if GameManager.container_scene.get_child_count() == 0:
			return

		get_viewport().set_input_as_handled()
		GameManager.return_to_main_menu()
		
