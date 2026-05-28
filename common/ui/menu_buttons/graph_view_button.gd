extends EditorMenuButton

func _build_menu() -> void:
	add_check_row("Snap", ConfigManager.get_config("snap"), _on_snap, true, ["mnl_graph_snap"])
	add_check_row("Show Grid", ConfigManager.get_config("show_grid"), _on_show_grid, true, ["mnl_graph_show_grid"])


func _on_snap(enabled: bool) -> void:
	ConfigManager.set_config("snap", enabled)
	EventBus.graph_snap.emit(enabled)


func _on_show_grid(enabled: bool) -> void:
	ConfigManager.set_config("show_grid", enabled)
	EventBus.graph_show_grid.emit(enabled)
