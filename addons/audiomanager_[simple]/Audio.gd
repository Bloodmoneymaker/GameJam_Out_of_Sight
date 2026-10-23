
## Audio.gd (Autoload)
# Dient als Datenbank für den AudioManager
extends Node

# find some better names :D
enum SOUND {Scan,B,C,RoachScream_1,UI_Hover,UI_Click,WaterDrop,PlayerHit,Beacon,PlayerStep_01,PlayerStep_02,PlayerStep_03,PlayerStep_04,PlayerStep_05,PlayerStep_06,Angel_01,Angel_02,Angel_03}
enum MUSIC {A,B,C}

# place your sound here
var sound:Dictionary = {
	SOUND.Scan : preload("res://Asset/AudioFX/Scanner_6.wav"),
	SOUND.B : preload("res://addons/audiomanager_[simple]/beep.mp3"),
	SOUND.C : preload("res://addons/audiomanager_[simple]/beep.mp3"),
	SOUND.RoachScream_1 : preload("res://Asset/AudioFX/roach_scream_01.wav"),
	SOUND.UI_Hover : preload("res://Asset/AudioFX/UI/ui_hover_fx_01.wav"),
	SOUND.UI_Click : preload("res://Asset/AudioFX/UI/ui_click_fx_01.wav"),
	SOUND.WaterDrop : preload("res://Asset/AudioFX/water_drop_fx_01.wav"),
	SOUND.PlayerHit : preload("res://Asset/AudioFX/Player_hit_01.wav"),
	SOUND.Beacon : preload("res://Asset/AudioFX/beacon_sfx_01.wav"),
	SOUND.PlayerStep_01 : preload("res://Asset/AudioFX/player_step_01.wav"),
	SOUND.PlayerStep_02 : preload("res://Asset/AudioFX/player_step_02.wav"),
	SOUND.PlayerStep_03 : preload("res://Asset/AudioFX/player_step_03.wav"),
	SOUND.PlayerStep_04 : preload("res://Asset/AudioFX/player_step_04.wav"),
	SOUND.PlayerStep_05 : preload("res://Asset/AudioFX/player_step_05.wav"),
	SOUND.PlayerStep_06 : preload("res://Asset/AudioFX/player_step_06.wav"),
	SOUND.Angel_01 : preload("res://Asset/AudioFX/Angel_sfx_01.wav"),
	SOUND.Angel_02 : preload("res://Asset/AudioFX/Angel_sfx_02.wav"),
	SOUND.Angel_03 : preload("res://Asset/AudioFX/Angel_sfx_03.wav")
}


# place your music here
var music:Dictionary = {
	MUSIC.A : preload("res://addons/audiomanager_[simple]/backing-up.mp3"),
	MUSIC.B : preload("res://addons/audiomanager_[simple]/backing-up.mp3"),
	MUSIC.C : preload("res://addons/audiomanager_[simple]/backing-up.mp3")
}
