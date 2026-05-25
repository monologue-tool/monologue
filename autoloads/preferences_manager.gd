extends Node

signal theme_changed

var current_preferences: PreferencesDocument
var command_manager: CommandManager = CommandManager.new()


func _ready() -> void:
	load_preferences()
	
	sync_theme()
	sync_fonts()


func load_preferences() -> PreferencesDocument:
	_ensure_preferences()
	
	var file: FileAccess = FileAccess.open(Constants.PREFERENCES_PATH, FileAccess.READ)
	var content: String = file.get_as_text()
	file.close()
	
	var data: Dictionary = JSON.parse_string(content)
	current_preferences = PreferencesDocument.new(command_manager)
	current_preferences._from_dict(data)
	
	return current_preferences


func save_preferences() -> void:
	var file: FileAccess = FileAccess.open(Constants.PREFERENCES_PATH, FileAccess.WRITE)
	var data: Dictionary = current_preferences._to_dict()
	var content: String = JSON.stringify(data, "\t")
	file.store_string(content)
	file.close()


func _ensure_preferences() -> void:
	if not FileAccess.file_exists(Constants.PREFERENCES_PATH):
		current_preferences = PreferencesDocument.new(command_manager)
		save_preferences()


func sync_theme() -> void:
	ThemeLayout.generate_and_apply_theme()
	theme_changed.emit()

func sync_fonts() -> void:
	#ThemeLayout.rebuild_fonts()
	pass
