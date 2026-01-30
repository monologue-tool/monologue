extends Node

# Reference DPI for a 23.8" 1920x1080 display
const BASE_SCALE_DPI: float = 92.56

# Application preferences config
var preferences: ConfigFile = ConfigFile.new()


func _ready() -> void:
	_load_preferences()
	_update_window(true)
	get_window().connect("size_changed", Callable(self, "_on_window_size_changed"))


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("Add node"):
		EventBus.enable_picker_mode.emit()


func _on_window_size_changed() -> void:
	_update_window()


func _update_window(update_size: bool = false) -> void:
	var screen_size: Vector2i = DisplayServer.window_get_size()
	var scale_factor: float = _get_auto_display_scale()
	get_window().content_scale_factor = scale_factor
	if update_size:
		DisplayServer.window_set_size(screen_size * scale_factor)
		get_window().move_to_center()


func _load_preferences() -> void:
	var err := preferences.load(Constants.PREFERENCES_PATH)
	if err != OK:
		push_warning("Failed to load preferences from %s" % Constants.PREFERENCES_PATH)


## Returns the optimal window scale factor for the current screen.
## Logic adapted from Godot editor/editor_settings.cpp:1564.
func _get_auto_display_scale() -> float:
	var os_name := OS.get_name()
	if os_name in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
		if DisplayServer.get_name() == "Wayland":
			var main_window_scale: float = DisplayServer.screen_get_scale(
				DisplayServer.SCREEN_OF_MAIN_WINDOW
			)
			if DisplayServer.get_screen_count() == 1:
				return main_window_scale
			return DisplayServer.screen_get_max_scale()
	if os_name in ["macOS", "Android"]:
		return DisplayServer.screen_get_max_scale()
	var screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	if screen_size == Vector2i():
		return 1.0  # Invalid screen size
	var smallest_dimension: int = min(screen_size.x, screen_size.y)
	var dpi: float = DisplayServer.screen_get_dpi(screen)
	if dpi >= 192.0 and smallest_dimension >= 1440:
		return 2.0  # hiDPI display
	elif smallest_dimension >= 1700:
		return 1.5  # likely hiDPI
	elif smallest_dimension <= 800:
		return 0.75  # small loDPI display
	return 1.0
