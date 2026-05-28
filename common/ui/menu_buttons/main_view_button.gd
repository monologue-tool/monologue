extends EditorMenuButton

func _build_menu() -> void:
	add_check_row("Show Inspector", ConfigManager.get_config("show_inspector"), _on_show_inspector)
	add_check_row("Show Project Explorer", ConfigManager.get_config("show_project_explorer"), _on_show_project_explorer)
	add_check_row("Show Console", ConfigManager.get_config("show_console"), _on_show_console)
	add_check_row("Show Status Bar", ConfigManager.get_config("show_status_bar"), _on_show_status_bar)
	add_separator()
	add_row("Regenerate theme", _on_regenerate_theme, true, ["mnl_regenerate_theme"])

func _on_show_inspector(enabled: bool) -> void:
	ConfigManager.set_config("show_inspector", enabled)
	EventBus.show_inspector.emit(enabled)

func _on_show_project_explorer(enabled: bool) -> void:
	ConfigManager.set_config("show_project_explorer", enabled)
	EventBus.show_project_explorer.emit(enabled)
	
func _on_show_console(enabled: bool) -> void:
	ConfigManager.set_config("show_console", enabled)
	EventBus.show_console.emit(enabled)

func _on_show_status_bar(enabled: bool) -> void:
	ConfigManager.set_config("show_status_bar", enabled)
	EventBus.show_status_bar.emit(enabled)

func _on_regenerate_theme() -> void:
	ThemeLayout.generate_and_apply_theme()
