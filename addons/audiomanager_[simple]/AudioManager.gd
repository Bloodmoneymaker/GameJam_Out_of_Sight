## AudioManager.gd (Autoload)
extends Node



var sound_players = {}
var music_player = null
var current_music_index = -1
var sound_player_amount:int = 100
var ui_sound_players: Array[AudioStreamPlayer] = []
@onready var current_music:AudioStream = null

func _ready() -> void:
	#Wird nicht durch Pause deaktiviert
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for i in sound_player_amount:
		var sound_player = AudioStreamPlayer3D.new()	#Audioplayer für 3D
		add_child(sound_player)
		sound_player.bus = "Sound"						# Player in den Audio-Bus zuweisen
		sound_players[i] = sound_player 				# Hinzufügen in den Array
	
	# UI-Soundplayer erstellen (nicht räumlich)
	for i in range(8):
		var ui_player = AudioStreamPlayer.new()
		add_child(ui_player)
		ui_player.bus = "Sound"
		ui_sound_players.append(ui_player)
	
	# Musicplayer erstellen
	music_player = AudioStreamPlayer.new()				# Benötigt keine räumliche Position
	add_child(music_player)
	music_player.bus = "Music"							# Player in den Audio-Bus zuweisen
	music_player.connect("finished",loop_music)

## Audio.SOUND.XXX, Position
func play_sound_3d(sound_idx:int,position:Vector3) -> void:
	play_sound_3d_special(Audio.sound[sound_idx],position,1.0,0)

## Spielt einen UI-Sound ohne räumliche Position ab
func play_sound_2d(sound_idx: int) -> void:
	for ui_player in ui_sound_players:
		if not ui_player.playing:
			ui_player.stream = Audio.sound[sound_idx]
			ui_player.play()
			return
	print("No available UI sound player!")


## AudioStream, Position,Pitchscale,Max-Distance (0 = unbegrenzt)
## Optional: Lautstärke in dB, unit_size (Distanz in m, bis zu der der Sound voll laut ist)
## und Abklingkurve. Die Standardwerte entsprechen Godots Defaults.
func play_sound_3d_special(sound:AudioStream,position:Vector3,pitch_scale:float,max_distance:float,volume_db:float = 0.0,unit_size:float = 10.0,attenuation:AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE) -> void:
	for sound_player in sound_players.values():
		if not sound_player.playing:
			# Player werden wiederverwendet: alle Einstellungen jedes Mal neu setzen
			sound_player.stream = sound
			sound_player.max_distance = max_distance
			sound_player.pitch_scale = pitch_scale
			sound_player.volume_db = volume_db
			sound_player.unit_size = unit_size
			sound_player.attenuation_model = attenuation
			sound_player.global_position = position
			sound_player.play()
			return
	print("No available sound player! Increase sound_player_amount.")
	

func play_music(music_idx:int) -> void:
	if current_music != null and music_player.playing:
		music_player.stop()
	music_player.stream = Audio.music[music_idx]
	music_player.play()
	current_music = Audio.music[music_idx]
	current_music_index = music_idx

func loop_music() -> void:
	if current_music_index != -1:
		play_music(current_music_index)

func stop_music() -> void:
	if music_player.playing:
		music_player.stop()
		music_player.stream = null
		current_music = null
