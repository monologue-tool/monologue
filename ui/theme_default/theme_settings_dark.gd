@tool
class_name ThemeSettingsDark extends ThemeSettings


func define_settings() -> void:
	text = Color("e3e4eb")
	primary = Color.from_hsv(0.667, 0.12, 0.14, 1.0)
	secondary = Color.from_hsv(0.661, 0.15, 0.19, 1.0)
	graph_bg = Color.from_hsv(0.656, 0.10, 0.10, 1.0)


func get_path() -> String:
	return "res://ui/theme_default/main.tres"
