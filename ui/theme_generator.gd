@tool
extends EditorScript

var _save_path_dark: String = "res://ui/theme_default/main.tres"
var _save_path_light: String = "res://ui/theme_default/main_light.tres"


func _run() -> void:
	# Generate dark theme
	var theme_dark := MonologueTheme.new(false)
	_update_existing_theme_instance(theme_dark, _save_path_dark)
	ResourceSaver.save(theme_dark, _save_path_dark)
	print("Dark theme generated and saved to: ", _save_path_dark)
	
	# Generate light theme
	var theme_light := MonologueTheme.new(true)
	_update_existing_theme_instance(theme_light, _save_path_light)
	ResourceSaver.save(theme_light, _save_path_light)
	print("Light theme generated and saved to: ", _save_path_light)


func _update_existing_theme_instance(new_theme: Theme, save_path: String):
	# When the editor uses the generated theme file, it loads the resource into
	# memory. This means that when the new theme is saved, the existing one in
	# memory is not updated or invalidated until the editor is restarted,
	# leaving the UI unaffected.
	# To fix this issue, the cached theme resource in memory is fetched and
	# mutated in-place (using the fact that when a resource is loaded, Godot uses
	# the shared instance in memory instead of loading a new instance from disk).

	if not ResourceLoader.exists(save_path):
		return

	var existing_theme = load(save_path)
	if not existing_theme is Theme:
		return

	existing_theme.clear()
	existing_theme.merge_with(new_theme)
