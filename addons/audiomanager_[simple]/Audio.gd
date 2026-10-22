## Audio.gd (Autoload)
# Dient als Datenbank für den AudioManager
extends Node

# find some better names :D
enum SOUND {A,B,C}
enum MUSIC {A,B,C}

# place your sound here
var sound:Dictionary = {
	SOUND.A : preload("res://addons/audiomanager_[simple]/beep.mp3"),
	SOUND.B : preload("res://addons/audiomanager_[simple]/beep.mp3"),
	SOUND.C : preload("res://addons/audiomanager_[simple]/beep.mp3"),
}

# place your music here
var music:Dictionary = {
	MUSIC.A : preload("res://addons/audiomanager_[simple]/backing-up.mp3"),
	MUSIC.B : preload("res://addons/audiomanager_[simple]/backing-up.mp3"),
	MUSIC.C : preload("res://addons/audiomanager_[simple]/backing-up.mp3")
}
