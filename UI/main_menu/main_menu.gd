extends Control

@onready var level_grid: GridContainer = $CenterContainer/MenuPanel/Margins/MenuContent/LevelGrid
@onready var quit_button: Button = $CenterContainer/MenuPanel/Margins/MenuContent/QuitButton


func _ready() -> void:
	quit_button.pressed.connect(_on_quit_pressed)
	_build_level_tiles()


func _build_level_tiles() -> void:
	for level_id in GameManager.scene.keys():
		var tile := Button.new()
		tile.text = GameManager.get_scene_title(level_id)
		tile.custom_minimum_size = Vector2(220, 116)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_font_size_override("font_size", 24)
		tile.add_theme_color_override("font_color", Color(0.78, 0.96, 1.0))
		tile.add_theme_stylebox_override("normal", _make_tile_style(Color(0.035, 0.09, 0.14, 0.96)))
		tile.add_theme_stylebox_override("hover", _make_tile_style(Color(0.04, 0.22, 0.29, 1.0)))
		tile.add_theme_stylebox_override("pressed", _make_tile_style(Color(0.02, 0.3, 0.37, 1.0)))
		tile.add_theme_stylebox_override("focus", _make_tile_style(Color(0.04, 0.22, 0.29, 1.0)))
		tile.pressed.connect(_on_level_selected.bind(level_id))
		level_grid.add_child(tile)


func _make_tile_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.1, 0.78, 0.88, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style


func _on_level_selected(level_id: int) -> void:
	GameManager.load_scene(level_id)


func _on_quit_pressed() -> void:
	get_tree().quit()
