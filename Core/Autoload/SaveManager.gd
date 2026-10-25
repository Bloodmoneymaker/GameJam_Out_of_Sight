extends Node
## user:// is stored in IndexedDB in Web exports and on disk in desktop builds.
## Numeric scene IDs must remain stable across releases.

const SAVE_PATH := "user://progress.cfg"
const SAVE_VERSION := 1


func _ready() -> void:
	load_progress()
	SignalManager.levelFinished.connect(save_progress)


func load_progress(path: String = SAVE_PATH) -> Error:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error == ERR_FILE_NOT_FOUND:
		return OK
	if error != OK:
		push_warning("Could not load progress: %s" % error_string(error))
		return error
	if config.get_value("save", "version", 0) != SAVE_VERSION:
		push_warning("Unsupported progress file version.")
		return ERR_INVALID_DATA

	GameManager.level_times.clear()
	GameManager.completed_missions.clear()
	for level_id in GameManager.scene.keys():
		var section := "level_%d" % int(level_id)
		var best_time: Variant = config.get_value(section, "best_time", -1.0)
		if typeof(best_time) in [TYPE_INT, TYPE_FLOAT]:
			var seconds := float(best_time)
			if is_finite(seconds) and seconds >= 0.0:
				GameManager.level_times[level_id] = seconds
		var completed: Variant = config.get_value(section, "completed", false)
		if typeof(completed) == TYPE_BOOL and completed:
			GameManager.completed_missions.append(level_id)
	SignalManager.updateEnabledLevel.emit()
	return OK


func save_progress(path: String = SAVE_PATH) -> Error:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	for level_id in GameManager.scene.keys():
		var section := "level_%d" % int(level_id)
		if GameManager.level_times.has(level_id):
			config.set_value(section, "best_time", GameManager.level_times[level_id])
		config.set_value(section, "completed", GameManager.completed_missions.has(level_id))
	var error := config.save(path)
	if error != OK:
		push_warning("Could not save progress: %s" % error_string(error))
	return error
