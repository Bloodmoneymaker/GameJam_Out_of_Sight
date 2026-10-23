extends Control

@export var level_tile_scene: PackedScene

@onready var level_grid: GridContainer = $MenuPanel/Margins/MenuContent/LevelGrid
@onready var quit_button: Button = $MenuPanel/Margins/MenuContent/Footer/QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	quit_button.pressed.connect(_on_quit_pressed)
	_build_level_tiles()


func _build_level_tiles() -> void:
	for level_id in GameManager.scene.keys():
		var tile: LevelTile = level_tile_scene.instantiate() as LevelTile
		tile.level_id = level_id
		tile.display_number = level_grid.get_child_count() + 1
		level_grid.add_child(tile)


func _on_quit_pressed() -> void:
	get_tree().quit()
