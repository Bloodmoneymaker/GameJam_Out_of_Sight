extends Control

@onready var return_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ReturnButton
@onready var retry_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RetryButton
@onready var next_button: Button = $CenterContainer/PanelContainer/VBoxContainer/NextButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	return_button.pressed.connect(_on_return_button_pressed)
	retry_button.pressed.connect(_on_retry_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	next_button.mouse_entered.connect(_play_hover_sound)
	next_button.focus_entered.connect(_play_hover_sound)
	return_button.mouse_entered.connect(_play_hover_sound)
	return_button.focus_entered.connect(_play_hover_sound)
	retry_button.mouse_entered.connect(_play_hover_sound)
	retry_button.focus_entered.connect(_play_hover_sound)


func show_win_screen() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	next_button.visible = GameManager.get_next_scene_id() != GameManager.SCENE.NONE
	if next_button.visible:
		next_button.grab_focus()
	else:
		retry_button.grab_focus()
	
	var total_seconds := int(GameManager.current_level_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	var text = "%02d:%02d" % [minutes, seconds]
	$CenterContainer/PanelContainer/VBoxContainer/Time.text = "Time: " +  text
	GameManager.addLevelTime(GameManager.current_level_time)
	
	GameManager.completed_missions.append(GameManager.get_current_scene())
	SignalManager.updateEnabledLevel.emit()


func _on_return_button_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.return_to_main_menu()


func _on_retry_button_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.retry_current_scene()


func _on_next_button_pressed() -> void:
	var next_scene_id: int = GameManager.get_next_scene_id()
	if next_scene_id == GameManager.SCENE.NONE:
		return
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	GameManager.load_scene(next_scene_id)


func _play_hover_sound() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Hover)
