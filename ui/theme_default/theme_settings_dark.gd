@tool
class_name ThemeSettingsDark extends ThemeSettings


func define_settings() -> void:
	text = Color("e8e8f0")
	primary = Color("1c1c21ff")
	secondary = Color("222229ff")
	tertiary = Color("14141aff")
	accent = Color("4870e8")


func get_path() -> String:
	return "res://ui/theme_default/main.tres"
