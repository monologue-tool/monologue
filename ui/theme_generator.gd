@tool
extends EditorScript


func _run() -> void:
	var settings_dark: ThemeSettingsDark = ThemeSettingsDark.new()
	var theme_dark: Theme = ThemeBuilder.build_theme(settings_dark)
	_update_existing_theme_instance(theme_dark, settings_dark.get_path())
	ResourceSaver.save(theme_dark, settings_dark.get_path())

	var settings_light: ThemeSettingsLight = ThemeSettingsLight.new()
	var theme_light: Theme = ThemeBuilder.build_theme(settings_light)
	_update_existing_theme_instance(theme_light, settings_light.get_path())
	ResourceSaver.save(theme_light, settings_light.get_path())


func _update_existing_theme_instance(new_theme: Theme, save_path: String) -> void:
	if not ResourceLoader.exists(save_path):
		return

	var existing_theme: Variant = load(save_path)
	if not existing_theme is Theme:
		return

	existing_theme.clear()
	existing_theme.merge_with(new_theme)
