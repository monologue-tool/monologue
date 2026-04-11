@tool
class_name ThemeSettingsDark extends ThemeSettings


func define_settings() -> void:
	text = Color("ececec")
	primary = Color("252525")
	secondary = Color("353535")
	tertiary = Color("1a1a1a")
	accent = Color("5b8dff")


func get_path() -> String:
	return "res://ui/theme_default/main.tres"
