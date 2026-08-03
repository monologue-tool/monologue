## Chooses which columns the localization window shows.
extends EditorMenuButton


func _build_menu() -> void:
	var window: LocalizationWindow = owner
	if window == null:
		return

	for column: Dictionary in window.get_columns():
		var column_id: String = str(column["id"])
		# The translation column is what the window is for; it is not one to turn off.
		add_check_row(
			str(column["title"]),
			window.is_column_visible(column_id),
			_on_toggled.bind(column_id),
			column_id != LocalizationWindow.TARGET_COLUMN
		)


func _on_toggled(shown: bool, column_id: String) -> void:
	var window: LocalizationWindow = owner
	if window:
		window.set_column_visible(column_id, shown)
