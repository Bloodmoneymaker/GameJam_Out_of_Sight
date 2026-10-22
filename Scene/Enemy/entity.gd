@tool
extends CharacterBody3D

@export var audio_player:AudioStreamPlayer3D
@export var timer:Timer
@export var animation_player:AnimationPlayer
@export var animation_tree:AnimationTree
@onready var ani_tree:AnimationTree = $Monster_Schabe/AnimationTree
var state_machine

@export var sound_movment:Array[AudioStream] = []
@export var sound_attack:Array[AudioStream] = []
@export var sound_body:AudioStream


@export var echo_speed:float = 2.0
@export var echo_lifetime:float = 1.0
@export var echo_intensity:float = 1.0
@export var echo_reflecting:bool = true
@export var echo_color:Color = Color.BURLYWOOD

@export var skeleton:Skeleton3D

@export var bones:Array[BoneAttachment3D] = []

func _ready() -> void:
	state_machine = animation_tree.get("parameters/playback") as AnimationNodeBlendTree
	audio_player.stream = sound_body
	audio_player.play()

func sound_trigger_movement() -> void:
	AudioManager.play_sound_3d_special(sound_movment.pick_random(),global_position,1.0,15)

func sound_trigger_position() -> void:
	AudioManager.play_sound_3d(0,global_position)

func send_echo() -> void:
	Echo.emit_wave(bones[0].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)

func send_xxx(xxx:int) -> void:
	match xxx:
		0:
			Echo.emit_wave(bones[0].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[2].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[4].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)

		1:
			Echo.emit_wave(bones[1].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[3].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[5].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)



func _on_timer_timeout() -> void:
	timer.start()
	if animation_tree.get("parameters/XXX/current_state") == "Walk":
		sound_trigger_movement()
	
