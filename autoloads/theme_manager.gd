extends Node
## Manages theme application and switching for the Monologue application

const THEME_PATH_DARK = "res://ui/theme_default/main.tres"
const THEME_PATH_LIGHT = "res://ui/theme_default/main_light.tres"

var current_theme: Theme
var is_light_theme: bool = false


func _ready() -> void:
	# Load and apply the default theme
	load_and_apply_theme(true)


## Load and apply a theme (dark or light)
func load_and_apply_theme(light: bool = false) -> void:
	is_light_theme = light
	var theme_path = THEME_PATH_LIGHT if light else THEME_PATH_DARK
	
	if not ResourceLoader.exists(theme_path):
		push_warning("Theme file not found: %s" % theme_path)
		return
	
	current_theme = load(theme_path)
	if not current_theme:
		push_error("Failed to load theme from: %s" % theme_path)
		return
	
	# Apply theme globally to the scene tree
	apply_theme_to_tree(current_theme)
	print("Theme loaded and applied: %s" % ("Light" if light else "Dark"))


## Apply theme to all Control nodes in the scene tree
func apply_theme_to_tree(theme: Theme) -> void:
	var root: Window = get_tree().root
	root.set_theme(theme)
	

## Switch between light and dark themes
func toggle_theme() -> void:
	load_and_apply_theme(not is_light_theme)


## Get the current theme
func get_current_theme() -> Theme:
	return current_theme
