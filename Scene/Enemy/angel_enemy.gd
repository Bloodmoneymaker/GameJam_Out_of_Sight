extends "res://Scene/Enemy/enemy.gd"
## Plays occasional, spatial Angel sounds without changing shared enemy behaviour.

const ANGEL_SOUNDS: Array[int] = [
	Audio.SOUND.Angel_01,
	Audio.SOUND.Angel_02,
	Audio.SOUND.Angel_03
]
const MIN_SOUND_INTERVAL := 10.0
const MAX_SOUND_INTERVAL := 22.0
const SOUND_MAX_DISTANCE := 24.0
const SOUND_VOLUME_DB := 0.0
const SOUND_UNIT_SIZE := 8.0

var _sound_timer: Timer


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return

	_sound_timer = Timer.new()
	_sound_timer.one_shot = true
	_sound_timer.timeout.connect(_play_random_sound)
	add_child(_sound_timer)
	_schedule_next_sound()


func _play_random_sound() -> void:
	if not is_inside_tree():
		return
	var sound_id: int = ANGEL_SOUNDS.pick_random()
	AudioManager.play_sound_3d_special(
		Audio.sound[sound_id],
		global_position,
		randf_range(0.95, 1.05),
		SOUND_MAX_DISTANCE,
		SOUND_VOLUME_DB,
		SOUND_UNIT_SIZE
	)
	_schedule_next_sound()


func _schedule_next_sound() -> void:
	_sound_timer.start(randf_range(MIN_SOUND_INTERVAL, MAX_SOUND_INTERVAL))
