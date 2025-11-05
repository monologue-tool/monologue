extends Node
## Manages theme generation, saving, and application for the Monologue application

const THEME_PATH_DARK = "res://ui/theme_default/main.tres"
const THEME_PATH_LIGHT = "res://ui/theme_default/main_light.tres"
const PaletteDark = preload("res://ui/theme_default/theme_palette_dark.gd")
const PaletteLight = preload("res://ui/theme_default/theme_palette_light.gd")
const ThemeBuilder = preload("res://ui/theme_default/theme_builder.gd")

var current_theme: Theme
var current_palette: RefCounted
var is_light_theme: bool = false


func _ready() -> void:
	# Generate and apply the default theme on startup
	generate_and_apply_theme(true)


## Generate a theme from a palette and apply it
func generate_and_apply_theme(light: bool = false) -> void:
	is_light_theme = light
	
	# Select the appropriate palette
	if is_light_theme:
		current_palette = PaletteLight.new()
	else:
		current_palette = PaletteDark.new()
	
	# Build the theme using ThemeBuilder
	current_theme = ThemeBuilder.build_theme(current_palette)
	
	if not current_theme:
		push_error("Failed to generate theme")
		return
	
	# Apply theme globally to the scene tree
	apply_theme_to_tree(current_theme)
	print("Theme generated and applied: %s" % ("Light" if light else "Dark"))


## Load a saved theme and apply it
func load_and_apply_theme(light: bool = false) -> void:
	is_light_theme = light
	var theme_path = THEME_PATH_LIGHT if light else THEME_PATH_DARK
	
	if not ResourceLoader.exists(theme_path):
		push_warning("Theme file not found: %s, generating instead" % theme_path)
		generate_and_apply_theme(light)
		return
	
	current_theme = load(theme_path)
	if not current_theme:
		push_error("Failed to load theme from: %s" % theme_path)
		return
	
	# Apply theme globally to the scene tree
	apply_theme_to_tree(current_theme)
	print("Theme loaded and applied: %s" % ("Light" if light else "Dark"))


## Save the current theme to disk
func save_current_theme() -> void:
	if not current_theme:
		push_error("No theme to save")
		return
	
	var theme_path = THEME_PATH_LIGHT if is_light_theme else THEME_PATH_DARK
	var err = ResourceSaver.save(current_theme, theme_path)
	
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


## Get the current palette
func get_current_palette() -> RefCounted:
	return current_palette
