extends CharacterBody3D

@export var sound_movment:Array[AudioStream] = []
@export var sound_attack:Array[AudioStream] = []
@export var sound_body:Array[AudioStream] = []


func sound_trigger_movement() -> void:
	var rng = -1
	var range = sound_movment.size() - 1
	
	AudioManager.play_sound_3d_special(0,global_position)

func sound_trigger_position() -> void:
	AudioManager.play_sound_3d(0,global_position)
