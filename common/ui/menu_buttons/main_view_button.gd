extends EditorMenuButton

func _build_menu() -> void:
	add_check_row("Show Inspector", ConfigManager.get_config("show_inspector"), _on_show_inspector)
	add_check_row("Show Project Explorer", ConfigManager.get_config("show_project_explorer"), _on_show_project_explorer)
	add_check_row("Show Console", ConfigManager.get_config("show_console"), _on_show_console)

func _on_show_inspector(enabled: bool) -> void:
	ConfigManager.set_config("show_inspector", enabled)
	EventBus.show_inspector.emit(enabled)

func _on_show_project_explorer(enabled: bool) -> void:
	ConfigManager.set_config("show_project_explorer", enabled)
	EventBus.show_project_explorer.emit(enabled)
	
func _on_show_console(enabled: bool) -> void:
	ConfigManager.set_config("show_console", enabled)
	EventBus.show_console.emit(enabled)
