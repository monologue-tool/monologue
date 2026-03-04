@tool
class_name ThemeSettingsLight extends ThemeSettings


func define_settings() -> void:
	text = Color("1a1a1f")
	primary = Color.from_hsv(0.646, 0.032, 0.988, 1.0)
	secondary = Color.from_hsv(0.0, 0.0, 1.0, 1.0)
	tertiary = Color.from_hsv(0.633, 0.038, 0.971, 1.0)


func get_path() -> String:
	return "res://ui/theme_default/main_light.tres"
