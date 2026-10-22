@tool
extends EditorPlugin
# Names
const AUDIO_NAME: String = "Audio"
const AUDIO_MANAGER_NAME: String = "AudioManager"
# Paths
const AUDIO_PATH: String = "res://addons/audiomanager_[simple]/Audio.gd"
const AUDIO_MANAGER_PATH: String = "res://addons/audiomanager_[simple]/AudioManager.gd"

func _enable_plugin() -> void:
	# Add autoloads here.
	add_autoload_singleton(AUDIO_NAME,AUDIO_PATH)
	add_autoload_singleton(AUDIO_MANAGER_NAME,AUDIO_MANAGER_PATH)


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_autoload_singleton(AUDIO_NAME)
	remove_autoload_singleton(AUDIO_MANAGER_NAME)
	


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
