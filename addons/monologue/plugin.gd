## Editor-side entry point of the Monologue runtime.
##
## What enabling the plugin buys is the `Monologue` autoload and the settings showing up in
## the project settings window with a sensible type. Nothing else needs it: every script the
## addon ships carries a class_name, so a project that would rather add the autoload by hand
## can, and a headless test builds a MonologueSession directly.
@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "Monologue"
const AUTOLOAD_PATH: String = "res://addons/monologue/monologue_runtime.gd"


func _enter_tree() -> void:
	for setting: String in [
		MonologueBehaviourIndexer.FOLDERS_SETTING, MonologueServiceIndexer.FOLDERS_SETTING
	]:
		_declare_folder_list(setting)

	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


## Left in the project on disable: a game that stops using the editor plugin still reads it.
func _declare_folder_list(setting: String) -> void:
	if not ProjectSettings.has_setting(setting):
		ProjectSettings.set_setting(setting, PackedStringArray())
	ProjectSettings.set_initial_value(setting, PackedStringArray())
	ProjectSettings.add_property_info({
		"name": setting,
		"type": TYPE_PACKED_STRING_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d/%d:" % [TYPE_STRING, PROPERTY_HINT_DIR],
	})
