extends Node


# The DPI of a 23.8 inch display with a 1920x1080 resolution
const BASE_SCALE_DPI = 92.56
# Application preferences
var preferences := ConfigFile.new()


func _ready() -> void:
	update_window(true)
	get_window().connect("size_changed", update_window)
	preferences.load(Constants.PREFERENCES_PATH)


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("Add node"):
		GlobalSignal.emit("enable_picker_mode")


func update_window(update_size: bool = false):
	var screen_size = DisplayServer.window_get_size()
	var scale_factor: float = get_auto_display_scale()
	
	get_window().content_scale_factor = scale_factor
	if update_size:
		DisplayServer.window_set_size(screen_size*scale_factor)
		get_window().move_to_center()


## A function that provides the right window scale for the screen on which the window is displayed.
## The logic is taken from Godot at editor/editor_settings.cpp:1564. 
func get_auto_display_scale() -> float:
	var os_name = OS.get_name()
	
	if os_name in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
		if DisplayServer.get_name() == "Wayland":
			var main_window_scale: float = DisplayServer.screen_get_scale(DisplayServer.SCREEN_OF_MAIN_WINDOW)
			
			if DisplayServer.get_screen_count() == 1:
				return main_window_scale
			
			return DisplayServer.screen_get_max_scale()
	if os_name in ["macOS", "Android"]:
		return DisplayServer.screen_get_max_scale()
	
	var screen: int = DisplayServer.window_get_current_screen()
	
	if DisplayServer.screen_get_size(screen) == Vector2i():
		# Invalid screen size, skip.
		return 1.0
	
	# Use the smallest dimension to use correct display scale portrait displays.
	var smallest_dimension = min(DisplayServer.screen_get_size(screen).x, DisplayServer.screen_get_size(screen).y)
	if DisplayServer.screen_get_dpi(screen) >= 192 && smallest_dimension >= 1440:
		# hiDPI display.
		return 2.0
	elif smallest_dimension >= 1700:
		# Likely hiDPI display, but aren't certain due to returned DPI.
		# Use intermediate scale to handle this situation.
		return 1.5
	elif smallest_dimension <= 800:
		# Small loDPI display. Use a smaller display scale so that editor elements fit more easily.
		# Icons won't look great, but this is better than having editor elements overflow from its window.
		return 0.75
	return 1.0
	
