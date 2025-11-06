@tool
class_name ThemeSettingsLight extends ThemeSettings


func define_settings() -> void:
	text = Color("1a1a1f")
	primary = Color.from_hsv(0.667, 0.08, 0.92, 1.0)
	secondary = Color.from_hsv(0.661, 0.10, 0.88, 1.0)
	graph_bg = Color.from_hsv(0.656, 0.05, 0.95, 1.0)


func get_path() -> String:
	return "res://ui/theme_default/main_light.tres"
