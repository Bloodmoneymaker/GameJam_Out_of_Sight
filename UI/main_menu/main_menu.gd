extends Control

@export var level_tile_scene: PackedScene
@export var enableAllLevel:bool = true
@onready var level_grid: GridContainer = $MenuPanel/Margins/MenuContent/LevelGrid
@onready var quit_button: Button = $MenuPanel/Margins/MenuContent/Footer/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit_button.pressed.connect(_on_quit_pressed)
	quit_button.mouse_entered.connect(_play_hover_sound)
	quit_button.focus_entered.connect(_play_hover_sound)
	_build_level_tiles()
	
	SignalManager.updateEnabledLevel.connect(_build_level_tiles)


func _build_level_tiles() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
		child.queue_free()
	var is_next_level_enabled: bool = true
	for level_id in GameManager.scene.keys():

		var tile: LevelTile = level_tile_scene.instantiate() as LevelTile
		var is_completed: bool = GameManager.completed_missions.has(level_id)
		if enableAllLevel or is_completed or is_next_level_enabled:
			tile.disabled = false
		else:
			tile.disabled = true
		is_next_level_enabled = is_completed

		tile.level_id = level_id
		tile.display_number = level_grid.get_child_count() + 1
		level_grid.add_child(tile)


func _on_quit_pressed() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Click)
	await get_tree().create_timer(
		Audio.sound[Audio.SOUND.UI_Click].get_length()
	).timeout
	get_tree().quit()


func _play_hover_sound() -> void:
	AudioManager.play_sound_2d(Audio.SOUND.UI_Hover)
