extends Node3D
class_name WaterDrop
## Falls straight down and sends a small echo where it hits something.

enum EchoSize {LIGHT, NORMAL}

@export var echo_size: EchoSize = EchoSize.NORMAL
@export var play_impact_sound: bool = true
@export var impact_sound: AudioStream = preload("res://Asset/AudioFX/water_drop_fx_01.wav")

const MAX_LIFETIME := 10.0
## Volume fades evenly from SOUND_VOLUME_DB at the drop to silence at this distance
## (half the volume, -6 dB, at half the distance). No extra boost close to the drop.
const SOUND_MAX_DISTANCE := 10.0
const SOUND_VOLUME_DB := -12.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _velocity := 0.0
var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > MAX_LIFETIME:
		queue_free()
		return

	_velocity += gravity * delta
	var from := global_position
	var to := from + Vector3.DOWN * _velocity * delta
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if hit:
		Echo.water_drop_echo(hit.position + hit.normal * 0.05, echo_size)
		# Slight pitch variation so repeated drips don't sound identical
		if play_impact_sound and impact_sound != null:
			AudioManager.play_sound_3d_special(impact_sound, hit.position, randf_range(0.9, 1.1), SOUND_MAX_DISTANCE,
					SOUND_VOLUME_DB, 1.0, AudioStreamPlayer3D.ATTENUATION_DISABLED)
		var splash := WaterSplash.new()
		splash.setup(hit.position, hit.normal)
		get_parent().add_child(splash)
		queue_free()
	else:
		global_position = to
