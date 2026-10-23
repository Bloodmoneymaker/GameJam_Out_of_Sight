@tool
class_name RoachEnemy
extends "res://Scene/Enemy/enemy.gd"

@export_group("Roach Animation")
@export var animation_player: AnimationPlayer
@export var animation_tree: AnimationTree
@export var skeleton: Skeleton3D
@export var bones: Array[BoneAttachment3D] = []

@export_group("Roach Audio")
@export var audio_player: AudioStreamPlayer3D
@export var timer: Timer
@export var sound_movment: Array[AudioStream] = []
@export var sound_attack: Array[AudioStream] = []
@export var sound_body: AudioStream

var _echo_step := false


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	_on_walking_changed(_is_walking)
	if is_instance_valid(audio_player) and sound_body != null:
		audio_player.stream = sound_body
		audio_player.play()


func _on_walking_changed(walking: bool) -> void:
	if is_instance_valid(animation_tree):
		animation_tree.set("parameters/XXX/transition_request", "Walk" if walking else "Idle")


func sound_trigger_movement() -> void:
	if not sound_movment.is_empty():
		AudioManager.play_sound_3d_special(sound_movment.pick_random(),global_position,1.0,15)

func sound_trigger_position() -> void:
	AudioManager.play_sound_3d(0,global_position)

func send_echo() -> void:
	_emit_bone_echo(0)


func send_xxx(xxx: int) -> void:
	if xxx == 0 or xxx == 1:
		for index in range(xxx, 6, 2):
			_emit_bone_echo(index)


func _emit_bone_echo(index: int) -> void:
	if Engine.is_editor_hint() or index >= bones.size() or not is_instance_valid(bones[index]):
		return
	Echo.spider_echo(bones[index].global_position)


func _on_timer_timeout() -> void:
	if not Engine.is_editor_hint() and _is_walking and not is_stunned():
		sound_trigger_movement()
		_echo_step = not _echo_step
		if _echo_step:
			Echo.spider_echo(global_position + Vector3.UP * 0.8)
