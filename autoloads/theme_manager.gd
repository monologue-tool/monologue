extends Node
## Manages theme generation, saving, and application for the Monologue application

var current_theme: Theme
var current_settings: ThemeSettings
var is_light_theme: bool = false


func _ready() -> void:
	generate_and_apply_theme(false)


## Generate a theme from a settings and apply it
func generate_and_apply_theme(light: bool = false) -> void:
	is_light_theme = light

	if is_light_theme:
		current_settings = ThemeSettingsLight.new()
	else:
		current_settings = ThemeSettingsDark.new()

	current_theme = ThemeBuilder.build_theme(current_settings)

	if not current_theme:
		push_error("Failed to generate theme")
		return

	apply_theme_to_tree(current_theme)
	print("Theme generated and applied: %s" % ("Light" if light else "Dark"))


## Save the current theme to disk
func save_current_theme() -> void:
	if not current_theme:
		push_error("No theme to save")
		return

	var theme_path: String = current_settings.get_path()
	var err: Error = ResourceSaver.save(current_theme, theme_path)

	if err == OK:
		print("Theme saved to: %s" % theme_path)
	else:
		push_error("Failed to save theme to: %s (error %d)" % [theme_path, err])


## Apply theme to all Control nodes in the scene tree
func apply_theme_to_tree(theme: Theme) -> void:
	var root: Window = get_tree().root
	root.set_theme(theme)


## Switch between light and dark themes
func toggle_theme() -> void:
	generate_and_apply_theme(not is_light_theme)


## Get the current theme
func get_current_theme() -> Theme:
	return current_theme


## Get the current settings
func get_current_settings() -> RefCounted:
	return current_settings
