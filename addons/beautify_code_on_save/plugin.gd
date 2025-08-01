@tool
extends EditorPlugin

const SUCCESS: int = 0
const AUTO_RELOAD_SETTING = "text_editor/behavior/files/auto_reload_scripts_on_external_change"
const ENABLE_EXTERNAL_EDITOR = "text_editor/external/use_external_editor"
# Plugin custom settings
const GDFORMAT_PATH_SETTING = "beautify_code_on_save/paths/gdformat_path"
const GDLINT_PATH_SETTING = "beautify_code_on_save/paths/gdlint_path"

var original_reload_setting: bool
var original_external_editor: bool


func _enter_tree() -> void:
	var settings = get_editor_interface().get_editor_settings()

	# Save original settings
	original_reload_setting = settings.get_setting(AUTO_RELOAD_SETTING)
	original_external_editor = settings.get_setting(ENABLE_EXTERNAL_EDITOR)

	# Configure auto-reload and external editor
	settings.set_setting(AUTO_RELOAD_SETTING, true)
	settings.set_setting(ENABLE_EXTERNAL_EDITOR, false)
	settings.set_initial_value(AUTO_RELOAD_SETTING, true, false)
	settings.set_initial_value(ENABLE_EXTERNAL_EDITOR, false, false)

	# Register plugin settings
	_setup_plugin_settings(settings)

	resource_saved.connect(_on_resource_saved_deferred)


func _exit_tree() -> void:
	resource_saved.disconnect(_on_resource_saved_deferred)

	var settings = get_editor_interface().get_editor_settings()
	settings.set_setting(AUTO_RELOAD_SETTING, original_reload_setting)
	settings.set_setting(ENABLE_EXTERNAL_EDITOR, original_external_editor)


func _setup_plugin_settings(settings: EditorSettings) -> void:
	# Detect default paths
	var default_gdformat = _detect_default_path("gdformat")
	var default_gdlint = _detect_default_path("gdlint")

	# Register settings
	if not settings.has_setting(GDFORMAT_PATH_SETTING):
		settings.set_setting(GDFORMAT_PATH_SETTING, default_gdformat)
	if not settings.has_setting(GDLINT_PATH_SETTING):
		settings.set_setting(GDLINT_PATH_SETTING, default_gdlint)

	# Configure settings metadata
	(
		settings
		.add_property_info(
			{
				"name": GDFORMAT_PATH_SETTING,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_GLOBAL_FILE,
				"hint_string": "",
			}
		)
	)
	(
		settings
		.add_property_info(
			{
				"name": GDLINT_PATH_SETTING,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_GLOBAL_FILE,
				"hint_string": "",
			}
		)
	)


func _detect_default_path(command: String) -> String:
	# Try to detect command path using 'which'
	var output = []
	var exit_code = OS.execute("which", [command], output, true)

	if exit_code == SUCCESS and not output.is_empty():
		return output[0].strip_edges()

	# Common paths as fallback
	var common_paths = [
		"/usr/local/bin/" + command,
		"/usr/bin/" + command,
		OS.get_environment("HOME") + "/.local/bin/" + command
	]

	for path in common_paths:
		if FileAccess.file_exists(path):
			return path

	return ""


func _on_resource_saved_deferred(script: Resource) -> void:
	call_deferred("_on_resource_saved", script)


func _on_resource_saved(script: Resource) -> void:
	if not script is Script:
		return

	var current_script = get_editor_interface().get_script_editor().get_current_script()
	if current_script != script:
		return

	var text_edit = (
		get_editor_interface().get_script_editor().get_current_editor().get_base_editor()
	)
	var file_path = ProjectSettings.globalize_path(script.resource_path)

	# Get paths from settings
	var settings = get_editor_interface().get_editor_settings()
	var gdformat_path = settings.get_setting(GDFORMAT_PATH_SETTING)
	var gdlint_path = settings.get_setting(GDLINT_PATH_SETTING)

	# Add date time
	var date_time = Time.get_datetime_string_from_system()
	print("\n%s" % date_time)

	# First run gdformat
	if not gdformat_path or not FileAccess.file_exists(gdformat_path):
		push_warning("❌ GDFormat not found. Please configure the path in Editor Settings.")
	else:
		var gdformat_output = []
		var gdformat_exit_code = OS.execute(gdformat_path, [file_path], gdformat_output, true)

		if gdformat_exit_code == SUCCESS:
			await get_tree().process_frame
			var formatted_source = FileAccess.get_file_as_string(script.resource_path)
			_reload_script(text_edit, formatted_source)
			print("✓ GDFormat: Successfully formatted: '%s'" % script.resource_path)
		else:
			push_error("❌ GDFormat Error: " + str(gdformat_output))
			return # If formatting fails, don't continue with linting

	# Then run gdlint on the formatted code
	if not gdlint_path or not FileAccess.file_exists(gdlint_path):
		push_warning("❌ GDLint not found. Please configure the path in Editor Settings.")
	else:
		var gdlint_output = []
		var gdlint_exit_code = OS.execute(gdlint_path, [file_path], gdlint_output, true)

		if gdlint_exit_code != SUCCESS:
			_show_lint_errors(gdlint_output[0], file_path)
		else:
			print("✓ GDLint  : Successfully linted   : '%s'" % script.resource_path)


func _reload_script(text_edit: TextEdit, source_code: String) -> void:
	# Save cursor and scroll position
	var column = text_edit.get_caret_column()
	var row = text_edit.get_caret_line()
	var scroll_position_h = text_edit.scroll_horizontal
	var scroll_position_v = text_edit.scroll_vertical

	# Update text
	text_edit.text = source_code

	# Restore cursor and scroll position

	text_edit.set_caret_column(column)
	text_edit.set_caret_line(row)
	text_edit.scroll_horizontal = scroll_position_h
	text_edit.scroll_vertical = scroll_position_v

	# Mark as saved
	text_edit.tag_saved_version()


func _show_lint_errors(output: String, path: String) -> void:
	print("\n⚠ GDLint found the following issues:")
	print("File: %s" % _get_res_path(path))
	push_error("❌ GDLint Error: Please see output with more information.")
	var lines = output.split("\n")
	var error_count := 0

	for line in lines:
		if line.is_empty() or line.begins_with("Failure:"):
			continue

		var error_parts = line.split(": Error: ")
		if error_parts.size() >= 2:
			error_count += 1
			var location = error_parts[0].get_file()
			var line_number = (
				error_parts[0].split(":")[2]
				if OS.get_name() == "Windows"
				else error_parts[0].split(":")[1]
			)
			var error_msg = error_parts[1]

			print("%d) Line %s: %s" % [error_count, line_number, error_msg])

	print("\nTotal: %d issues found" % error_count)


func _get_res_path(absolute_path: String) -> String:
	var project_root = ProjectSettings.globalize_path("res://")
	if absolute_path.begins_with(project_root):
		return "res://" + absolute_path.substr(project_root.length())
	var addons_pos = absolute_path.find("/addons/")
	if addons_pos != -1:
		return "res://" + absolute_path.substr(addons_pos + 1)
	return absolute_path
