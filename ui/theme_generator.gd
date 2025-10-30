## Editor script for generating and saving the Monologue theme.
##
## This tool script generates the MonologueTheme and saves it to disk.
## It also updates the existing theme instance in memory to avoid requiring
## an editor restart to see theme changes.
@tool
extends EditorScript

## Path where the generated theme will be saved.
var _save_path: String = "res://ui/theme_default/main.tres"


## Runs the theme generation process.
##
## Creates a new MonologueTheme, updates any existing cached instance,
## and saves it to disk.
func _run() -> void:
	var theme := MonologueTheme.new()
	_update_existing_theme_instance(theme)
	ResourceSaver.save(theme, _save_path)
	print("Theme generated!")


## Updates the existing theme instance in memory with the new theme.
##
## When the editor uses a theme file, it loads it into memory. This method
## fetches the cached resource and updates it in-place to reflect changes
## without requiring an editor restart.
## [br][br]
## [param new_theme] The newly generated theme to apply.
func _update_existing_theme_instance(new_theme: Theme):
	# When the editor uses the generated theme file, it loads the resource into
	# memory. This means that when the new theme is saved, the existing one in
	# memory is not updated or invalidated until the editor is restarted,
	# leaving the UI unaffected.
	# To fix this issue, the cached theme resource in memory is fetched and
	# mutated in-place (using the fact that when a resource is loaded, Godot uses
	# the shared instance in memory instead of loading a new instance from disk).

	if not ResourceLoader.exists(_save_path):
		return

	var existing_theme = load(_save_path)
	if not existing_theme is Theme:
		return

	existing_theme.clear()
	existing_theme.merge_with(new_theme)
